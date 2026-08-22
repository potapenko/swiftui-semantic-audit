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
