import AuditCore
import Foundation
import ProjectWorkspace
import SnapshotStore
import Testing
import WatcherRuntime

@Suite("Watcher runtime primitives")
struct WatcherRuntimeTests {
    @Test("typed build adapters issue exact bounded commands")
    func typedBuildAdapters() throws {
        let fixture = try Fixture()
        defer { try? FileManager.default.removeItem(at: fixture.root) }

        let swiftStore = fixture.project.appendingPathComponent(".build/debug/index/store", isDirectory: true)
        try makeRawStore(at: swiftStore)
        let swiftRunner = BuildRunner()
        let selectedSwiftStore = try ProjectBuilder(runner: swiftRunner).build(
            projectRoot: fixture.project,
            manifest: fixture.manifest,
            runtimeRoot: fixture.root.appendingPathComponent("swift-runtime", isDirectory: true),
            timeout: 9
        )
        #expect(selectedSwiftStore == swiftStore.standardizedFileURL.resolvingSymlinksInPath())
        #expect(swiftRunner.lastCall == BuildCall(
            command: "swift", arguments: ["build"], currentDirectory: fixture.project.path, timeout: 9
        ))

        let container = fixture.project.appendingPathComponent("App.xcodeproj", isDirectory: true)
        try FileManager.default.createDirectory(at: container, withIntermediateDirectories: true)
        let xcodeRuntime = fixture.root.appendingPathComponent("xcode-runtime", isDirectory: true)
        let xcodeStore = xcodeRuntime.appendingPathComponent(
            "DerivedData/Index.noindex/DataStore", isDirectory: true
        )
        try makeRawStore(at: xcodeStore)
        let xcodeRunner = BuildRunner()
        let xcodeManifest = ProjectManifest(
            sourceRoot: "Sources",
            build: ProjectBuildConfiguration(
                kind: .xcode,
                container: "App.xcodeproj",
                scheme: "App",
                platform: "macOS"
            )
        )
        let selectedXcodeStore = try ProjectBuilder(runner: xcodeRunner).build(
            projectRoot: fixture.project,
            manifest: xcodeManifest,
            runtimeRoot: xcodeRuntime,
            timeout: 11
        )
        #expect(selectedXcodeStore == xcodeStore.standardizedFileURL.resolvingSymlinksInPath())
        #expect(xcodeRunner.lastCall == BuildCall(
            command: "xcodebuild",
            arguments: [
                "-project", "App.xcodeproj",
                "-scheme", "App",
                "-destination", "generic/platform=macOS",
                "-derivedDataPath", xcodeRuntime.appendingPathComponent("DerivedData").path,
                "COMPILER_INDEX_STORE_ENABLE=YES",
                "build",
            ],
            currentDirectory: fixture.project.path,
            timeout: 11
        ))
    }

    @Test("managed service start and stop are idempotent")
    func serviceLifecycle() throws {
        let fixture = try Fixture()
        defer { try? FileManager.default.removeItem(at: fixture.root) }
        let support = fixture.root.appendingPathComponent("ApplicationSupport", isDirectory: true)
        let runner = ServiceRunner()
        let controller = ProjectServiceController(runner: runner, timeout: 1)

        let started = try controller.start(
            projectRoot: fixture.project,
            executable: URL(fileURLWithPath: "/usr/bin/true"),
            applicationSupportRoot: support
        )
        #expect(started.running && started.changed)
        let repeated = try controller.start(
            projectRoot: fixture.project,
            executable: URL(fileURLWithPath: "/usr/bin/true"),
            applicationSupportRoot: support
        )
        #expect(repeated.running && !repeated.changed)
        let stopped = try controller.stop(
            projectRoot: fixture.project,
            applicationSupportRoot: support
        )
        #expect(!stopped.running && stopped.changed)
        let repeatedStop = try controller.stop(
            projectRoot: fixture.project,
            applicationSupportRoot: support
        )
        #expect(!repeatedStop.running && !repeatedStop.changed)
    }

    @Test("one-shot watcher publishes and promotes fresh indexed state")
    func indexedEndToEnd() throws {
        let fixture = try Fixture(validPackage: true)
        defer { try? FileManager.default.removeItem(at: fixture.root) }
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let helper = repositoryRoot.appendingPathComponent(".build/debug/swiftui-audit")
        let stateRoot = fixture.root.appendingPathComponent("ApplicationSupport", isDirectory: true)
        let watcher = WatcherCoordinator(timeout: 120)

        let status = try watcher.runOnce(
            projectRoot: fixture.project,
            helperExecutable: helper,
            applicationSupportRoot: stateRoot
        )
        #expect(status.fresh)
        #expect(status.resolution == "indexed")
        #expect(status.workspaceDigest == status.indexedWorkspaceDigest)
        let snapshot = try SnapshotReader().read(
            from: URL(fileURLWithPath: status.liveSnapshotPath!, isDirectory: true)
        )
        #expect(snapshot.graph.resolution == "indexed")

        let promoted = try watcher.promoteBaseline(
            projectRoot: fixture.project,
            applicationSupportRoot: stateRoot
        )
        #expect(promoted.fresh)
        _ = try SnapshotReader().read(from: fixture.manifest.baselineURL(projectRoot: fixture.project))

        try Data("public struct App { public let value = 1 }\n".utf8).write(to: fixture.source)
        let stale = try watcher.status(
            projectRoot: fixture.project,
            applicationSupportRoot: stateRoot
        )
        #expect(!stale.fresh)
        #expect(stale.generation == status.generation)
        #expect(stale.liveSnapshotPath == status.liveSnapshotPath)
        #expect(throws: WatcherRuntimeError.self) {
            _ = try watcher.promoteBaseline(
                projectRoot: fixture.project,
                applicationSupportRoot: stateRoot
            )
        }
    }

    @Test("workspace digest changes with source content")
    func digestChanges() throws {
        let fixture = try Fixture()
        defer { try? FileManager.default.removeItem(at: fixture.root) }
        let before = try WorkspaceDigest.compute(projectRoot: fixture.project, manifest: fixture.manifest)
        try Data("struct App { let value = 1 }\n".utf8).write(to: fixture.source)
        let after = try WorkspaceDigest.compute(projectRoot: fixture.project, manifest: fixture.manifest)
        #expect(before != after)
    }

    @Test("project lock permits one writer")
    func lockExclusion() throws {
        let fixture = try Fixture()
        defer { try? FileManager.default.removeItem(at: fixture.root) }
        let lockURL = fixture.root.appendingPathComponent("watcher.lock")
        let first = try ProjectLock(url: lockURL)
        _ = first
        #expect(throws: ProjectLockError.self) {
            _ = try ProjectLock(url: lockURL)
        }
    }

    @Test("status store round trips canonical state")
    func statusRoundTrip() throws {
        let fixture = try Fixture()
        defer { try? FileManager.default.removeItem(at: fixture.root) }
        let url = fixture.root.appendingPathComponent("status.json")
        let status = ProjectStatus(
            projectID: "project",
            serviceState: .indexedReady,
            generation: 2,
            workspaceDigest: "digest",
            indexedWorkspaceDigest: "digest",
            fresh: true,
            resolution: "indexed",
            baselinePath: "baseline"
        )
        try ProjectStatusStore().save(status, to: url)
        #expect(ProjectStatusStore().load(from: url) == status)
    }
}

private struct BuildCall: Equatable {
    let command: String
    let arguments: [String]
    let currentDirectory: String?
    let timeout: TimeInterval
}

private final class BuildRunner: @unchecked Sendable, ProcessRunning {
    private let lock = NSLock()
    private var call: BuildCall?

    var lastCall: BuildCall? {
        lock.lock()
        defer { lock.unlock() }
        return call
    }

    func run(
        _ command: String,
        arguments: [String],
        currentDirectory: URL?,
        timeout: TimeInterval
    ) throws -> BoundedProcessResult {
        lock.lock()
        call = BuildCall(
            command: command,
            arguments: arguments,
            currentDirectory: currentDirectory?.path,
            timeout: timeout
        )
        lock.unlock()
        return BoundedProcessResult(status: 0, standardOutput: Data(), standardError: Data())
    }
}

private func makeRawStore(at store: URL) throws {
    let version = store.appendingPathComponent("v5", isDirectory: true)
    try FileManager.default.createDirectory(
        at: version.appendingPathComponent("units", isDirectory: true),
        withIntermediateDirectories: true
    )
    try FileManager.default.createDirectory(
        at: version.appendingPathComponent("records", isDirectory: true),
        withIntermediateDirectories: true
    )
}

private final class ServiceRunner: @unchecked Sendable, ProcessRunning {
    private let lock = NSLock()
    private var running = false

    func run(
        _ command: String,
        arguments: [String],
        currentDirectory: URL?,
        timeout: TimeInterval
    ) throws -> BoundedProcessResult {
        lock.lock()
        defer { lock.unlock() }
        switch arguments.first {
        case "print":
            return result(status: running ? 0 : 1)
        case "bootstrap":
            running = true
            return result(status: 0)
        case "bootout":
            running = false
            return result(status: 0)
        default:
            return result(status: 1)
        }
    }

    private func result(status: Int32) -> BoundedProcessResult {
        BoundedProcessResult(status: status, standardOutput: Data(), standardError: Data())
    }
}

private struct Fixture {
    let root: URL
    let project: URL
    let source: URL
    let manifest: ProjectManifest

    init(validPackage: Bool = false) throws {
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("watcher-runtime-tests-\(UUID().uuidString)", isDirectory: true)
        project = root.appendingPathComponent("Project", isDirectory: true)
        source = project.appendingPathComponent("Sources/App.swift")
        try FileManager.default.createDirectory(
            at: source.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try Data("public struct App { public init() {} }\n".utf8).write(to: source)
        if validPackage {
            try Data("""
            // swift-tools-version: 6.2
            import PackageDescription
            let package = Package(name: "WatcherFixture", products: [.library(name: "WatcherFixture", targets: ["WatcherFixture"])], targets: [.target(name: "WatcherFixture", path: "Sources")])
            """.utf8).write(to: project.appendingPathComponent("Package.swift"))
        }
        manifest = ProjectManifest(
            sourceRoot: "Sources",
            build: ProjectBuildConfiguration(kind: .swiftPM)
        )
        let manifestURL = project.appendingPathComponent(".swiftui-audit/project.json")
        try FileManager.default.createDirectory(
            at: manifestURL.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try manifest.canonicalData().write(to: manifestURL)
    }
}
