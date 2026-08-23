import Foundation
import ProjectWorkspace
import Testing

@Suite("Project workspace setup")
struct ProjectWorkspaceTests {
    @Test("preview is non-mutating and apply is idempotent")
    func previewAndApply() throws {
        let fixture = try Fixture()
        defer { try? FileManager.default.removeItem(at: fixture.root) }
        let planner = ProjectSetupPlanner()
        let stateRoot = fixture.root.appendingPathComponent("state", isDirectory: true)
        let preview = try planner.plan(projectRoot: fixture.project, applicationSupportRoot: stateRoot)
        #expect(preview.ready)
        #expect(!preview.applied)
        #expect(!FileManager.default.fileExists(atPath: preview.manifestPath))

        let applied = try planner.apply(preview)
        #expect(applied.applied)
        let bytes = try Data(contentsOf: URL(fileURLWithPath: preview.manifestPath))
        let second = try planner.plan(projectRoot: fixture.project, applicationSupportRoot: stateRoot)
        #expect(second.writes.isEmpty)
        _ = try planner.apply(second)
        #expect(try Data(contentsOf: URL(fileURLWithPath: preview.manifestPath)) == bytes)
    }

    @Test("legacy manifests keep the 300 second default and remain byte-identical on apply")
    func legacyManifestCompatibility() throws {
        let fixture = try Fixture()
        defer { try? FileManager.default.removeItem(at: fixture.root) }
        let manifestURL = fixture.project.appendingPathComponent(".swiftui-audit/project.json")
        try FileManager.default.createDirectory(
            at: manifestURL.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        let legacyData = Data("""
        {
          "baseline" : ".swiftui-audit/baseline",
          "build" : {
            "kind" : "swiftpm"
          },
          "schemaVersion" : 1,
          "sourceRoot" : "Sources",
          "watch" : {
            "debounceMilliseconds" : 250,
            "indexQuiescenceMilliseconds" : 1000
          }
        }

        """.utf8)
        try legacyData.write(to: manifestURL)

        let loaded = try ProjectManifest.load(projectRoot: fixture.project)
        #expect(
            loaded.watch.buildAndAnalysisTimeoutSeconds
                == ProjectWatchConfiguration.defaultBuildAndAnalysisTimeoutSeconds
        )
        let canonical = String(decoding: try loaded.canonicalData(), as: UTF8.self)
        #expect(canonical.contains("\"buildAndAnalysisTimeoutSeconds\" : 300"))

        let stateRoot = fixture.root.appendingPathComponent("state", isDirectory: true)
        let plan = try ProjectSetupPlanner().plan(
            projectRoot: fixture.project,
            applicationSupportRoot: stateRoot
        )
        _ = try ProjectSetupPlanner().apply(plan)
        #expect(try Data(contentsOf: manifestURL) == legacyData)
    }

    @Test("setup validates and canonically preserves a configured watcher timeout")
    func configuredWatcherTimeout() throws {
        let fixture = try Fixture()
        defer { try? FileManager.default.removeItem(at: fixture.root) }
        let planner = ProjectSetupPlanner()
        let stateRoot = fixture.root.appendingPathComponent("state", isDirectory: true)
        let preview = try planner.plan(
            projectRoot: fixture.project,
            options: ProjectSetupOptions(watchTimeout: 900),
            applicationSupportRoot: stateRoot
        )
        #expect(preview.manifest?.watch.buildAndAnalysisTimeoutSeconds == 900)
        _ = try planner.apply(preview)
        #expect(
            try ProjectManifest.load(projectRoot: fixture.project)
                .watch.buildAndAnalysisTimeoutSeconds == 900
        )

        let existingBytes = try Data(contentsOf: URL(fileURLWithPath: preview.manifestPath))
        let conflicting = try planner.plan(
            projectRoot: fixture.project,
            options: ProjectSetupOptions(watchTimeout: 1200),
            applicationSupportRoot: stateRoot
        )
        #expect(!conflicting.ready)
        #expect(conflicting.blockers.count == 1)
        #expect(throws: ProjectWorkspaceError.self) {
            _ = try planner.apply(conflicting)
        }
        #expect(try Data(contentsOf: URL(fileURLWithPath: preview.manifestPath)) == existingBytes)

        for invalidTimeout in [0, -1, .infinity, .nan] {
            let invalidFixture = try Fixture()
            defer { try? FileManager.default.removeItem(at: invalidFixture.root) }
            #expect(throws: ProjectWorkspaceError.self) {
                _ = try planner.plan(
                    projectRoot: invalidFixture.project,
                    options: ProjectSetupOptions(watchTimeout: invalidTimeout),
                    applicationSupportRoot: invalidFixture.root.appendingPathComponent("state")
                )
            }
        }
    }

    @Test("setup discovers only root or selected source-root configuration with root precedence")
    func analysisConfigurationPrecedence() throws {
        let nestedFixture = try Fixture()
        defer { try? FileManager.default.removeItem(at: nestedFixture.root) }
        let selectedSource = nestedFixture.project.appendingPathComponent("PlayphrasemeApp", isDirectory: true)
        try FileManager.default.createDirectory(at: selectedSource, withIntermediateDirectories: true)
        try Data("{\"schemaVersion\":2}\n".utf8).write(
            to: selectedSource.appendingPathComponent(".swiftui-audit.json")
        )
        let nestedPlan = try ProjectSetupPlanner().plan(
            projectRoot: nestedFixture.project,
            options: ProjectSetupOptions(sourceRoot: "PlayphrasemeApp")
        )
        #expect(nestedPlan.manifest?.analysisConfiguration == "PlayphrasemeApp/.swiftui-audit.json")
        _ = try ProjectSetupPlanner().apply(nestedPlan)
        #expect(
            try ProjectManifest.load(projectRoot: nestedFixture.project).analysisConfiguration
                == "PlayphrasemeApp/.swiftui-audit.json"
        )

        let rootFixture = try Fixture()
        defer { try? FileManager.default.removeItem(at: rootFixture.root) }
        let rootSelectedSource = rootFixture.project.appendingPathComponent("PlayphrasemeApp", isDirectory: true)
        try FileManager.default.createDirectory(at: rootSelectedSource, withIntermediateDirectories: true)
        try Data("{\"schemaVersion\":2}\n".utf8).write(
            to: rootSelectedSource.appendingPathComponent(".swiftui-audit.json")
        )
        try Data("{\"schemaVersion\":1}\n".utf8).write(
            to: rootFixture.project.appendingPathComponent(".swiftui-audit.json")
        )
        let rootPlan = try ProjectSetupPlanner().plan(
            projectRoot: rootFixture.project,
            options: ProjectSetupOptions(sourceRoot: "PlayphrasemeApp")
        )
        #expect(rootPlan.manifest?.analysisConfiguration == ".swiftui-audit.json")
    }

    @Test("setup never adds a newly discovered source-root config to an existing manifest")
    func existingManifestRemainsAuthoritative() throws {
        let fixture = try Fixture()
        defer { try? FileManager.default.removeItem(at: fixture.root) }
        let manifest = ProjectManifest(
            sourceRoot: "Sources",
            build: ProjectBuildConfiguration(kind: .swiftPM)
        )
        let manifestURL = fixture.project.appendingPathComponent(".swiftui-audit/project.json")
        try FileManager.default.createDirectory(
            at: manifestURL.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try manifest.canonicalData().write(to: manifestURL)
        let before = try Data(contentsOf: manifestURL)
        try Data("{\"schemaVersion\":2}\n".utf8).write(
            to: fixture.project.appendingPathComponent("Sources/.swiftui-audit.json")
        )

        let planner = ProjectSetupPlanner()
        let plan = try planner.plan(projectRoot: fixture.project)
        #expect(plan.manifest?.analysisConfiguration == nil)
        _ = try planner.apply(plan)
        #expect(try Data(contentsOf: manifestURL) == before)
    }

    @Test("unsafe manifest paths fail closed")
    func unsafePath() throws {
        let fixture = try Fixture()
        defer { try? FileManager.default.removeItem(at: fixture.root) }
        let manifest = ProjectManifest(
            sourceRoot: "../Outside",
            build: ProjectBuildConfiguration(kind: .swiftPM)
        )
        #expect(throws: ProjectWorkspaceError.self) {
            try manifest.validate(projectRoot: fixture.project)
        }
    }

    @Test("apply rejects a conflicting manifest created after preview")
    func conflictingApply() throws {
        let fixture = try Fixture()
        defer { try? FileManager.default.removeItem(at: fixture.root) }
        let planner = ProjectSetupPlanner()
        let stateRoot = fixture.root.appendingPathComponent("state", isDirectory: true)
        let preview = try planner.plan(projectRoot: fixture.project, applicationSupportRoot: stateRoot)
        let manifestURL = URL(fileURLWithPath: preview.manifestPath)
        try FileManager.default.createDirectory(
            at: manifestURL.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try Data("{}\n".utf8).write(to: manifestURL)

        #expect(throws: ProjectWorkspaceError.self) {
            _ = try planner.apply(preview)
        }
    }

    @Test("source roots cannot escape through symlinks")
    func symlinkEscape() throws {
        let fixture = try Fixture()
        defer { try? FileManager.default.removeItem(at: fixture.root) }
        let outside = fixture.root.appendingPathComponent("Outside", isDirectory: true)
        try FileManager.default.createDirectory(at: outside, withIntermediateDirectories: true)
        let link = fixture.project.appendingPathComponent("Linked", isDirectory: true)
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: outside)
        let manifest = ProjectManifest(
            sourceRoot: "Linked",
            build: ProjectBuildConfiguration(kind: .swiftPM)
        )

        #expect(throws: ProjectWorkspaceError.self) {
            try manifest.validate(projectRoot: fixture.project)
        }
    }
}

private struct Fixture {
    let root: URL
    let project: URL

    init() throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("project-workspace-tests-\(UUID().uuidString)", isDirectory: true)
        project = root.appendingPathComponent("Project", isDirectory: true)
        try FileManager.default.createDirectory(
            at: project.appendingPathComponent("Sources"), withIntermediateDirectories: true
        )
        try Data("// swift-tools-version: 6.2\n".utf8).write(
            to: project.appendingPathComponent("Package.swift")
        )
        try Data("struct App {}\n".utf8).write(
            to: project.appendingPathComponent("Sources/App.swift")
        )
    }
}
