import AnalysisCache
import AuditCore
import Foundation
import ProjectWorkspace
import SemanticDiff
import SnapshotStore
import SymbolResolution

public struct WatcherCoordinator: Sendable {
    private let builder: ProjectBuilder
    private let statusStore: ProjectStatusStore
    private let timeout: TimeInterval

    public init(
        runner: any ProcessRunning = BoundedProcessRunner(),
        timeout: TimeInterval = 300
    ) {
        builder = ProjectBuilder(runner: runner)
        statusStore = ProjectStatusStore()
        self.timeout = timeout
    }

    @discardableResult
    public func runOnce(
        projectRoot requestedRoot: URL,
        helperExecutable: URL,
        applicationSupportRoot: URL? = nil,
        acquireLock: Bool = true
    ) throws -> ProjectStatus {
        let root = requestedRoot.standardizedFileURL.resolvingSymlinksInPath()
        let manifest = try ProjectManifest.load(projectRoot: root)
        let locations = ProjectRuntimeLocations(projectRoot: root, applicationSupportRoot: applicationSupportRoot)
        let lock = acquireLock ? try ProjectLock(url: locations.lock) : nil
        defer { _ = lock }
        let previous = statusStore.load(from: locations.status)
        let generation = (previous?.generation ?? 0) + 1
        let digest = try WorkspaceDigest.compute(projectRoot: root, manifest: manifest)
        let baselinePath = manifest.baselineURL(projectRoot: root).path
        do {
            try saveStatus(
                locations: locations,
                projectRoot: root,
                manifest: manifest,
                generation: generation,
                digest: digest,
                state: .starting
            )
            try writePreview(
                root: root,
                manifest: manifest,
                locations: locations,
                helperExecutable: helperExecutable
            )
            try saveStatus(
                locations: locations,
                projectRoot: root,
                manifest: manifest,
                generation: generation,
                digest: digest,
                state: .buildingIndex
            )
            let store = try builder.build(
                projectRoot: root, manifest: manifest, runtimeRoot: locations.root, timeout: timeout
            )
            let source = manifest.sourceURL(projectRoot: root)
            let cache = AnalysisCacheStore(sourceRoot: source)
            let loaded = try SemanticInputLoader(timeout: timeout).loadLive(
                sourceURL: source,
                indexSelection: .explicit(store),
                configurationURL: manifest.configurationURL(projectRoot: root),
                helperExecutable: helperExecutable,
                indexTimeout: timeout,
                cache: cache
            )
            guard loaded.snapshot.graph.resolution == "indexed",
                  loaded.snapshot.report.resolution == "indexed" else {
                throw ProjectBuildError.indexStore("analysis did not produce indexed resolution")
            }
            let currentDigest = try WorkspaceDigest.compute(projectRoot: root, manifest: manifest)
            guard currentDigest == digest else {
                throw WatcherRuntimeError.superseded
            }
            try SnapshotWriter().write(
                graph: loaded.snapshot.graph,
                report: loaded.snapshot.report,
                manifest: loaded.snapshot.manifest,
                sourceURL: source,
                to: locations.liveSnapshot
            )
            let comparison = compareBaseline(
                baseline: manifest.baselineURL(projectRoot: root), current: loaded.snapshot
            )
            let status = ProjectStatus(
                projectID: locations.projectID,
                serviceState: .indexedReady,
                generation: generation,
                workspaceDigest: digest,
                indexedWorkspaceDigest: digest,
                fresh: true,
                resolution: "indexed",
                indexStorePath: store.path,
                configurationDigest: loaded.snapshot.graph.configurationDigest,
                liveSnapshotPath: locations.liveSnapshot.path,
                baselinePath: baselinePath,
                baselineCompatible: comparison.compatible,
                diff: comparison.summary
            )
            try statusStore.save(status, to: locations.status)
            return status
        } catch {
            let status = ProjectStatus(
                projectID: locations.projectID,
                serviceState: .failed,
                generation: generation,
                workspaceDigest: digest,
                indexedWorkspaceDigest: previous?.indexedWorkspaceDigest,
                fresh: false,
                resolution: previous?.resolution,
                indexStorePath: previous?.indexStorePath,
                configurationDigest: previous?.configurationDigest,
                liveSnapshotPath: previous?.liveSnapshotPath,
                baselinePath: baselinePath,
                baselineCompatible: previous?.baselineCompatible,
                diff: previous?.diff,
                lastError: compact(error.localizedDescription)
            )
            try? statusStore.save(status, to: locations.status)
            throw error
        }
    }

    public func watch(
        projectRoot requestedRoot: URL,
        helperExecutable: URL,
        applicationSupportRoot: URL? = nil
    ) throws -> Never {
        let root = requestedRoot.standardizedFileURL.resolvingSymlinksInPath()
        let locations = ProjectRuntimeLocations(projectRoot: root, applicationSupportRoot: applicationSupportRoot)
        let lock = try ProjectLock(url: locations.lock)
        _ = lock
        var lastDigest = ""
        while true {
            let manifest = try ProjectManifest.load(projectRoot: root)
            let digest = try WorkspaceDigest.compute(projectRoot: root, manifest: manifest)
            if digest != lastDigest {
                Thread.sleep(forTimeInterval: Double(manifest.watch.indexQuiescenceMilliseconds) / 1000)
                do {
                    _ = try runOnce(
                        projectRoot: root,
                        helperExecutable: helperExecutable,
                        applicationSupportRoot: applicationSupportRoot,
                        acquireLock: false
                    )
                    lastDigest = try WorkspaceDigest.compute(projectRoot: root, manifest: manifest)
                } catch WatcherRuntimeError.superseded {
                    continue
                } catch {
                    lastDigest = digest
                }
            }
            Thread.sleep(forTimeInterval: Double(manifest.watch.debounceMilliseconds) / 1000)
        }
    }

    public func status(
        projectRoot requestedRoot: URL,
        applicationSupportRoot: URL? = nil
    ) throws -> ProjectStatus {
        let root = requestedRoot.standardizedFileURL.resolvingSymlinksInPath()
        let manifest = try ProjectManifest.load(projectRoot: root)
        let locations = ProjectRuntimeLocations(projectRoot: root, applicationSupportRoot: applicationSupportRoot)
        let digest = try WorkspaceDigest.compute(projectRoot: root, manifest: manifest)
        guard let saved = statusStore.load(from: locations.status) else {
            return ProjectStatus(
                projectID: locations.projectID,
                serviceState: .stopped,
                generation: 0,
                workspaceDigest: digest,
                fresh: false,
                baselinePath: manifest.baselineURL(projectRoot: root).path
            )
        }
        let liveSnapshot = saved.liveSnapshotPath.flatMap {
            try? SnapshotReader().read(from: URL(fileURLWithPath: $0, isDirectory: true))
        }
        guard saved.toolVersion == ToolMetadata.version,
              saved.workspaceDigest == digest, saved.indexedWorkspaceDigest == digest,
              saved.resolution == "indexed", saved.serviceState == .indexedReady,
              liveSnapshot?.graph.resolution == "indexed",
              liveSnapshot?.report.resolution == "indexed",
              liveSnapshot?.graph.configurationDigest == saved.configurationDigest else {
            return ProjectStatus(
                projectID: saved.projectID,
                serviceState: saved.serviceState,
                generation: saved.generation,
                workspaceDigest: digest,
                indexedWorkspaceDigest: saved.indexedWorkspaceDigest,
                fresh: false,
                resolution: saved.resolution,
                indexStorePath: saved.indexStorePath,
                configurationDigest: saved.configurationDigest,
                liveSnapshotPath: saved.liveSnapshotPath,
                baselinePath: saved.baselinePath,
                baselineCompatible: saved.baselineCompatible,
                diff: saved.diff,
                lastError: saved.lastError
            )
        }
        return saved
    }

    public func promoteBaseline(
        projectRoot requestedRoot: URL,
        applicationSupportRoot: URL? = nil
    ) throws -> ProjectStatus {
        let root = requestedRoot.standardizedFileURL.resolvingSymlinksInPath()
        let manifest = try ProjectManifest.load(projectRoot: root)
        let current = try status(projectRoot: root, applicationSupportRoot: applicationSupportRoot)
        guard current.fresh, current.resolution == "indexed", let live = current.liveSnapshotPath else {
            throw WatcherRuntimeError.stale
        }
        let snapshot = try SnapshotReader().read(from: URL(fileURLWithPath: live, isDirectory: true))
        try SnapshotWriter().write(
            graph: snapshot.graph,
            report: snapshot.report,
            manifest: snapshot.manifest,
            sourceURL: manifest.sourceURL(projectRoot: root),
            to: manifest.baselineURL(projectRoot: root)
        )
        let locations = ProjectRuntimeLocations(projectRoot: root, applicationSupportRoot: applicationSupportRoot)
        let promoted = ProjectStatus(
            projectID: current.projectID,
            serviceState: current.serviceState,
            generation: current.generation,
            workspaceDigest: current.workspaceDigest,
            indexedWorkspaceDigest: current.indexedWorkspaceDigest,
            fresh: current.fresh,
            resolution: current.resolution,
            indexStorePath: current.indexStorePath,
            configurationDigest: current.configurationDigest,
            liveSnapshotPath: current.liveSnapshotPath,
            baselinePath: current.baselinePath,
            baselineCompatible: true,
            diff: ProjectDiffSummary(changes: 0, newFindings: 0, resolvedFindings: 0)
        )
        try statusStore.save(promoted, to: locations.status)
        return promoted
    }

    private func writePreview(
        root: URL,
        manifest: ProjectManifest,
        locations: ProjectRuntimeLocations,
        helperExecutable: URL
    ) throws {
        let source = manifest.sourceURL(projectRoot: root)
        let loaded = try SemanticInputLoader(timeout: timeout).loadLive(
            sourceURL: source,
            indexSelection: .syntaxOnly,
            configurationURL: manifest.configurationURL(projectRoot: root),
            helperExecutable: helperExecutable,
            cache: AnalysisCacheStore(sourceRoot: source)
        )
        try SnapshotWriter().write(
            graph: loaded.snapshot.graph,
            report: loaded.snapshot.report,
            manifest: loaded.snapshot.manifest,
            sourceURL: source,
            to: locations.previewSnapshot
        )
    }

    private func saveStatus(
        locations: ProjectRuntimeLocations,
        projectRoot: URL,
        manifest: ProjectManifest,
        generation: Int,
        digest: String,
        state: ProjectServiceState
    ) throws {
        try statusStore.save(
            ProjectStatus(
                projectID: locations.projectID,
                serviceState: state,
                generation: generation,
                workspaceDigest: digest,
                fresh: false,
                baselinePath: manifest.baselineURL(projectRoot: projectRoot).path
            ),
            to: locations.status
        )
    }

    private func compareBaseline(
        baseline: URL,
        current: SemanticSnapshot
    ) -> (compatible: Bool?, summary: ProjectDiffSummary?) {
        guard FileManager.default.fileExists(atPath: baseline.path),
              let base = try? SnapshotReader().read(from: baseline) else { return (nil, nil) }
        guard base.graph.resolution == current.graph.resolution,
              base.graph.configurationDigest == current.graph.configurationDigest else { return (false, nil) }
        let report = SemanticDiffEngine().compare(base: base, current: current)
        return (
            true,
            ProjectDiffSummary(
                changes: report.changes.count,
                newFindings: report.newFindings.count,
                resolvedFindings: report.resolvedFindings.count
            )
        )
    }

    private func compact(_ value: String) -> String {
        String(value.split(whereSeparator: \.isWhitespace).joined(separator: " ").prefix(1000))
    }
}

public enum WatcherRuntimeError: Error, LocalizedError {
    case stale
    case superseded

    public var errorDescription: String? {
        switch self {
        case .stale: "project has no fresh indexed watcher snapshot"
        case .superseded: "analysis generation was superseded by a newer source state"
        }
    }
}
