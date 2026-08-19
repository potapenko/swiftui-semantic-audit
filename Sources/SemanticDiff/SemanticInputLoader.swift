import AnalysisCache
import AuditCore
import AuditRules
import Foundation
import SnapshotStore
import SymbolResolution
import SwiftSyntaxFrontend

public struct LoadedSemanticInput: Sendable {
    public let snapshot: SemanticSnapshot
    public let identity: String

    public init(snapshot: SemanticSnapshot, identity: String) {
        self.snapshot = snapshot
        self.identity = identity
    }
}

public enum SemanticInputError: Error, Equatable, LocalizedError {
    case invalidRevision(String)
    case noSwiftFiles(String)
    case unsafeGitPath(String)
    case resolutionMismatch(baseline: String, current: String)
    case configurationMismatch(baseline: String, current: String)

    public var errorDescription: String? {
        switch self {
        case .invalidRevision(let revision): "invalid git revision \(revision)"
        case .noSwiftFiles(let revision): "git revision \(revision) contains no Swift source files"
        case .unsafeGitPath(let path): "unsafe path in git tree: \(path)"
        case .resolutionMismatch(let baseline, let current):
            "semantic resolution mismatch: baseline is \(baseline), current is \(current). " +
                "Use a baseline with the same resolution, provide a usable --index-store for an indexed baseline, " +
                "or pass --syntax-only with a syntax-only baseline."
        case .configurationMismatch(let baseline, let current):
            "analysis configuration mismatch: baseline is \(baseline), current is \(current). " +
                "Use inputs produced from the same canonical .swiftui-audit.json configuration."
        }
    }
}

public struct SemanticInputLoader: Sendable {
    private let runner: any ProcessRunning
    private let timeout: TimeInterval

    public init(runner: any ProcessRunning = BoundedProcessRunner(), timeout: TimeInterval = 10) {
        self.runner = runner
        self.timeout = timeout
    }

    public func loadOperand(_ operand: String, repositoryURL: URL) throws -> LoadedSemanticInput {
        let candidate = URL(fileURLWithPath: operand).standardizedFileURL
        if FileManager.default.fileExists(atPath: candidate.path) {
            let snapshot = try SnapshotReader().read(from: candidate)
            return LoadedSemanticInput(snapshot: snapshot, identity: snapshotIdentity(snapshot.manifest))
        }
        return try loadRevision(operand, repositoryURL: repositoryURL)
    }

    public func loadRevision(_ revision: String, repositoryURL: URL) throws -> LoadedSemanticInput {
        let repository = try repositoryRoot(from: repositoryURL)
        let commitResult = try runChecked(
            "git",
            ["-C", repository.path, "rev-parse", "--verify", "\(revision)^{commit}"]
        )
        let commit = commitResult.outputString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !commit.isEmpty else { throw SemanticInputError.invalidRevision(revision) }
        let listing = try runChecked(
            "git",
            ["-C", repository.path, "ls-tree", "-r", "-z", "--full-tree", commit, "--"]
        )
        let treeEntries = try parseTreeEntries(listing.standardOutput)
        let entries = treeEntries.filter {
            ($0.mode == "100644" || $0.mode == "100755") && $0.type == "blob" &&
                URL(fileURLWithPath: $0.path).pathExtension.lowercased() == "swift"
        }.sorted { $0.path < $1.path }
        guard !entries.isEmpty else { throw SemanticInputError.noSwiftFiles(revision) }
        let configurationEntry = treeEntries.first {
            ($0.mode == "100644" || $0.mode == "100755") && $0.type == "blob" &&
                $0.path == ".swiftui-audit.json"
        }

        let container = FileManager.default.temporaryDirectory
            .appendingPathComponent("swiftui-audit-revision-\(UUID().uuidString)", isDirectory: true)
        let sourceRoot = container.appendingPathComponent(repository.lastPathComponent, isDirectory: true)
        try FileManager.default.createDirectory(at: sourceRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: container) }
        for entry in entries + [configurationEntry].compactMap({ $0 }) {
            try validateGitPath(entry.path)
            let destination = sourceRoot.appendingPathComponent(entry.path)
            try FileManager.default.createDirectory(
                at: destination.deletingLastPathComponent(), withIntermediateDirectories: true
            )
            let blob = try runChecked("git", ["-C", repository.path, "cat-file", "blob", entry.objectID])
            try blob.standardOutput.write(to: destination, options: .atomic)
            if entry.mode == "100755" {
                try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: destination.path)
            }
        }
        let syntaxGraph = try GraphScanner().scan(path: sourceRoot.path)
        let configuration = try AnalysisConfiguration.load(explicitURL: nil, sourceURL: sourceRoot)
        let graph = configuration?.applying(to: syntaxGraph) ?? syntaxGraph
        let report = AuditEngine().audit(graph: graph)
        let manifest = SnapshotManifest(
            toolVersion: report.toolVersion,
            swiftVersion: swiftVersion(),
            repositoryRevision: commit,
            generatedFrom: ".",
            configurationDigest: graph.configurationDigest
        )
        return LoadedSemanticInput(
            snapshot: SemanticSnapshot(manifest: manifest, graph: graph, report: report),
            identity: commit
        )
    }

    public func loadLive(
        sourceURL: URL,
        indexSelection: IndexSelection = .syntaxOnly,
        configurationURL: URL? = nil,
        helperExecutable: URL? = nil,
        indexTimeout: TimeInterval = 30,
        cache: AnalysisCacheStore? = nil
    ) throws -> LoadedSemanticInput {
        let source = sourceURL.standardizedFileURL.resolvingSymlinksInPath()
        let scan = try GraphScanner().scan(path: source.path, previousState: cache?.loadFrontendState())
        try? cache?.saveFrontendState(scan.state)
        let configuration = try AnalysisConfiguration.load(explicitURL: configurationURL, sourceURL: source)
        let syntaxGraph = configuration?.applying(to: scan.graph) ?? scan.graph
        let graph: SemanticGraph
        if indexSelection == .syntaxOnly {
            graph = syntaxGraph
        } else {
            guard let helperExecutable else {
                throw IndexResolutionError.unavailableLibrary("helper executable was not provided")
            }
            graph = try IndexEnrichmentCoordinator(
                helperExecutable: helperExecutable,
                runner: runner,
                timeout: indexTimeout
            ).enrich(graph: syntaxGraph, sourceRoot: source, selection: indexSelection, cache: cache)
        }
        let report = AuditEngine().audit(graph: graph)
        let revision = (try? repositoryRevision(for: source)) ?? "unavailable"
        let manifest = SnapshotManifest(
            toolVersion: report.toolVersion,
            swiftVersion: swiftVersion(),
            repositoryRevision: revision,
            generatedFrom: ".",
            configurationDigest: graph.configurationDigest
        )
        return LoadedSemanticInput(
            snapshot: SemanticSnapshot(manifest: manifest, graph: graph, report: report),
            identity: "working:\(source.lastPathComponent)"
        )
    }

    public func loadComparableLive(
        sourceURL: URL,
        baseline: LoadedSemanticInput,
        requestedSelection: IndexSelection,
        configurationURL: URL? = nil,
        helperExecutable: URL? = nil,
        indexTimeout: TimeInterval = 30,
        cache: AnalysisCacheStore? = nil
    ) throws -> LoadedSemanticInput {
        let baselineResolution = baseline.snapshot.graph.resolution
        guard baseline.snapshot.report.resolution == baselineResolution else {
            throw SemanticInputError.resolutionMismatch(
                baseline: "inconsistent graph/report (\(baselineResolution)/\(baseline.snapshot.report.resolution))",
                current: "not loaded"
            )
        }
        let selection: IndexSelection
        switch (baselineResolution, requestedSelection) {
        case ("syntax-only", .automatic), ("syntax-only", .syntaxOnly):
            selection = .syntaxOnly
        case ("syntax-only", .explicit):
            throw SemanticInputError.resolutionMismatch(baseline: baselineResolution, current: "explicit indexed")
        case ("indexed", .syntaxOnly):
            throw SemanticInputError.resolutionMismatch(baseline: baselineResolution, current: "syntax-only")
        case ("indexed", .automatic), ("indexed", .explicit):
            selection = requestedSelection
        default:
            throw SemanticInputError.resolutionMismatch(baseline: baselineResolution, current: "unsupported")
        }
        let current = try loadLive(
            sourceURL: sourceURL,
            indexSelection: selection,
            configurationURL: configurationURL,
            helperExecutable: helperExecutable,
            indexTimeout: indexTimeout,
            cache: cache
        )
        try validateMatchingResolution(base: baseline, current: current)
        return current
    }

    public func validateMatchingResolution(base: LoadedSemanticInput, current: LoadedSemanticInput) throws {
        let baselineResolution = base.snapshot.graph.resolution
        let currentResolution = current.snapshot.graph.resolution
        guard base.snapshot.report.resolution == baselineResolution,
              current.snapshot.report.resolution == currentResolution,
              baselineResolution == currentResolution
        else {
            throw SemanticInputError.resolutionMismatch(
                baseline: base.snapshot.report.resolution == baselineResolution
                    ? baselineResolution
                    : "inconsistent graph/report (\(baselineResolution)/\(base.snapshot.report.resolution))",
                current: current.snapshot.report.resolution == currentResolution
                    ? currentResolution
                    : "inconsistent graph/report (\(currentResolution)/\(current.snapshot.report.resolution))"
            )
        }
        let baselineConfiguration = base.snapshot.graph.configurationDigest
        let currentConfiguration = current.snapshot.graph.configurationDigest
        guard base.snapshot.report.configurationDigest == baselineConfiguration,
              current.snapshot.report.configurationDigest == currentConfiguration,
              base.snapshot.manifest.configurationDigest == baselineConfiguration,
              current.snapshot.manifest.configurationDigest == currentConfiguration,
              baselineConfiguration == currentConfiguration else {
            throw SemanticInputError.configurationMismatch(
                baseline: baselineConfiguration,
                current: currentConfiguration
            )
        }
    }

    private func repositoryRoot(from url: URL) throws -> URL {
        let result = try runChecked("git", ["-C", url.standardizedFileURL.path, "rev-parse", "--show-toplevel"])
        return URL(
            fileURLWithPath: result.outputString.trimmingCharacters(in: .whitespacesAndNewlines),
            isDirectory: true
        ).standardizedFileURL.resolvingSymlinksInPath()
    }

    private func repositoryRevision(for source: URL) throws -> String {
        let root = try repositoryRoot(from: source)
        return try runChecked("git", ["-C", root.path, "rev-parse", "HEAD"])
            .outputString.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func swiftVersion() -> String {
        guard let result = try? runner.run("swift", arguments: ["--version"], currentDirectory: nil, timeout: timeout),
              result.status == 0 else { return "unavailable" }
        return result.outputString.replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func runChecked(_ command: String, _ arguments: [String]) throws -> BoundedProcessResult {
        let result: BoundedProcessResult
        do {
            result = try runner.run(command, arguments: arguments, currentDirectory: nil, timeout: timeout)
        } catch {
            throw error
        }
        guard result.status == 0 else {
            if command == "git", arguments.contains("--verify") {
                let requested = arguments.last ?? "unknown"
                throw SemanticInputError.invalidRevision(String(requested).replacingOccurrences(of: "^{commit}", with: ""))
            }
            throw BoundedProcessError.failed(
                ([command] + arguments).joined(separator: " "),
                result.status,
                result.errorString.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }
        return result
    }

    private func validateGitPath(_ path: String) throws {
        let components = NSString(string: path).pathComponents
        if path.hasPrefix("/") || components.contains("..") || path.contains("\0") {
            throw SemanticInputError.unsafeGitPath(path)
        }
    }

    private func parseTreeEntries(_ data: Data) throws -> [GitTreeEntry] {
        try data.split(separator: 0).map { record in
            guard let tab = record.firstIndex(of: 0x09) else {
                throw BoundedProcessError.failed("git ls-tree", 0, "malformed tree record")
            }
            let header = record[..<tab].split(separator: 0x20, omittingEmptySubsequences: true)
            guard header.count == 3 else {
                throw BoundedProcessError.failed("git ls-tree", 0, "malformed tree metadata")
            }
            let pathBytes = record[record.index(after: tab)...]
            guard let path = String(bytes: pathBytes, encoding: .utf8) else {
                throw SemanticInputError.unsafeGitPath("<non-UTF8>")
            }
            return GitTreeEntry(
                mode: String(decoding: header[0], as: UTF8.self),
                type: String(decoding: header[1], as: UTF8.self),
                objectID: String(decoding: header[2], as: UTF8.self),
                path: path
            )
        }
    }

    private func snapshotIdentity(_ manifest: SnapshotManifest) -> String {
        manifest.repositoryRevision == "unavailable"
            ? "snapshot:\(manifest.generatedFrom)"
            : manifest.repositoryRevision
    }
}

private struct GitTreeEntry {
    let mode: String
    let type: String
    let objectID: String
    let path: String
}
