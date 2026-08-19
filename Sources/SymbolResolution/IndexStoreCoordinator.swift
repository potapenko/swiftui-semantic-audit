import AnalysisCache
import AuditCore
import Darwin
import Foundation

public enum IndexResolutionError: Error, Equatable, LocalizedError {
    case invalidStore(String)
    case noProjectCoverage(String)
    case unavailableLibrary(String)
    case invalidHelper(String)
    case helperFailed(Int32, String)
    case invalidResponse(String)

    public var errorDescription: String? {
        switch self {
        case .invalidStore(let path): "invalid Index Store: \(path)"
        case .noProjectCoverage(let path): "Index Store has no coverage for analyzed Swift files: \(path)"
        case .unavailableLibrary(let detail): "Index Store library unavailable: \(detail)"
        case .invalidHelper(let path): "index enrichment helper is not a regular executable file: \(path)"
        case .helperFailed(let status, let detail):
            "index enrichment helper failed with status \(status)\(detail.isEmpty ? "" : ": \(detail)")"
        case .invalidResponse(let detail): "invalid index enrichment response: \(detail)"
        }
    }
}

public struct IndexStoreLocator: Sendable {
    public init() {}

    public func validatedExplicitStore(_ url: URL) throws -> URL {
        let canonical = url.standardizedFileURL.resolvingSymlinksInPath()
        guard Self.hasRawStoreShape(canonical) else {
            throw IndexResolutionError.invalidStore(canonical.path)
        }
        return canonical
    }

    public func automaticStores(sourceRoot: URL) -> [URL] {
        var isDirectory: ObjCBool = false
        let canonicalSource = sourceRoot.standardizedFileURL.resolvingSymlinksInPath()
        let root = FileManager.default.fileExists(atPath: canonicalSource.path, isDirectory: &isDirectory) && isDirectory.boolValue
            ? canonicalSource
            : canonicalSource.deletingLastPathComponent()
        let build = root.appendingPathComponent(".build", isDirectory: true)
        var candidates: [URL] = [
            build.appendingPathComponent("debug/index/store", isDirectory: true),
            build.appendingPathComponent("release/index/store", isDirectory: true),
        ]
        if let triples = try? FileManager.default.contentsOfDirectory(
            at: build, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]
        ) {
            for triple in triples.sorted(by: { $0.path < $1.path }) {
                candidates.append(triple.appendingPathComponent("debug/index/store", isDirectory: true))
                candidates.append(triple.appendingPathComponent("release/index/store", isDirectory: true))
            }
        }
        var byPath: [String: URL] = [:]
        for candidate in candidates {
            let canonical = candidate.standardizedFileURL.resolvingSymlinksInPath()
            if Self.hasRawStoreShape(canonical) { byPath[canonical.path] = canonical }
        }
        return byPath.values.sorted { $0.path < $1.path }
    }

    public static func hasRawStoreShape(_ store: URL) -> Bool {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: store.path, isDirectory: &isDirectory), isDirectory.boolValue,
              let versions = try? FileManager.default.contentsOfDirectory(
                at: store, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]
              )
        else { return false }
        return versions.contains { version in
            let name = version.lastPathComponent
            guard name.first == "v", Int(name.dropFirst()) != nil else { return false }
            var unitsDirectory: ObjCBool = false
            var recordsDirectory: ObjCBool = false
            return FileManager.default.fileExists(
                atPath: version.appendingPathComponent("units").path, isDirectory: &unitsDirectory
            ) && unitsDirectory.boolValue && FileManager.default.fileExists(
                atPath: version.appendingPathComponent("records").path, isDirectory: &recordsDirectory
            ) && recordsDirectory.boolValue
        }
    }
}

public struct IndexEnrichmentCoordinator: Sendable {
    private let runner: any ProcessRunning
    private let helperExecutable: URL
    private let timeout: TimeInterval
    private let temporaryRoot: URL

    public init(
        helperExecutable: URL,
        runner: any ProcessRunning = BoundedProcessRunner(),
        timeout: TimeInterval = 120,
        temporaryRoot: URL = FileManager.default.temporaryDirectory
    ) {
        self.helperExecutable = helperExecutable
        self.runner = runner
        self.timeout = timeout
        self.temporaryRoot = temporaryRoot
    }

    public func enrich(
        graph: SemanticGraph,
        sourceRoot: URL,
        selection: IndexSelection,
        cache: AnalysisCacheStore? = nil
    ) throws -> SemanticGraph {
        guard selection != .syntaxOnly else { return graph }
        let locator = IndexStoreLocator()
        let explicit: Bool
        let store: URL
        switch selection {
        case .syntaxOnly:
            return graph
        case .explicit(let path):
            explicit = true
            store = try locator.validatedExplicitStore(path)
        case .automatic:
            explicit = false
            let candidates = locator.automaticStores(sourceRoot: sourceRoot)
            guard candidates.count == 1, let only = candidates.first else { return graph }
            store = only
        }

        do {
            let library = try indexStoreLibraryPath()
            let cacheKey = try cache.map { _ in try indexedCacheKey(graph: graph, store: store, library: library) }
            if let cache, let cacheKey, let cached = cache.loadIndexedGraph(key: cacheKey),
               cached.resolution == "indexed",
               cached.configurationDigest == graph.configurationDigest {
                return cached
            }
            let enriched = try invokeHelper(
                graph: graph, sourceRoot: sourceRoot, store: store, library: library, cache: cache
            )
            if let cache, let cacheKey { try? cache.saveIndexedGraph(enriched, key: cacheKey) }
            return enriched
        } catch {
            if explicit { throw error }
            return graph
        }
    }

    private func indexedCacheKey(graph: SemanticGraph, store: URL, library: URL) throws -> String {
        var data = try graph.jsonData()
        data.append(Data("|cache:\(AnalysisCacheStore.schemaVersion)|tool:\(ToolMetadata.version)|".utf8))
        let fileManager = FileManager.default
        let unitURLs = (fileManager.enumerator(
            at: store,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )?.compactMap { $0 as? URL }.filter {
            $0.path.contains("/units/") &&
                (try? $0.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true
        } ?? []).sorted { $0.path < $1.path }
        let prefix = store.path.hasSuffix("/") ? store.path : store.path + "/"
        for unit in unitURLs {
            let relative = unit.path.hasPrefix(prefix) ? String(unit.path.dropFirst(prefix.count)) : unit.lastPathComponent
            data.append(Data(relative.utf8))
            data.append(try Data(contentsOf: unit))
        }
        let libraryValues = try library.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
        data.append(Data("|library:\(library.path)|\(libraryValues.fileSize ?? 0)|\(libraryValues.contentModificationDate?.timeIntervalSince1970 ?? 0)".utf8))
        return AnalysisCacheStore.digest(data)
    }

    private func indexStoreLibraryPath() throws -> URL {
        let result = try runner.run("/usr/bin/xcrun", arguments: ["--find", "swiftc"], currentDirectory: nil, timeout: timeout)
        guard result.status == 0 else {
            throw IndexResolutionError.unavailableLibrary(result.errorString.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        let swiftc = URL(
            fileURLWithPath: result.outputString.trimmingCharacters(in: .whitespacesAndNewlines)
        ).standardizedFileURL.resolvingSymlinksInPath()
        let library = swiftc.deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("lib/libIndexStore.dylib")
        guard FileManager.default.fileExists(atPath: library.path) else {
            throw IndexResolutionError.unavailableLibrary(library.path)
        }
        return library
    }

    private func invokeHelper(
        graph: SemanticGraph,
        sourceRoot: URL,
        store: URL,
        library: URL,
        cache: AnalysisCacheStore?
    ) throws -> SemanticGraph {
        let fileManager = FileManager.default
        let helper = helperExecutable.standardizedFileURL.resolvingSymlinksInPath()
        guard let helperValues = try? helper.resourceValues(forKeys: [.isRegularFileKey]),
              helperValues.isRegularFile == true,
              fileManager.isExecutableFile(atPath: helper.path)
        else { throw IndexResolutionError.invalidHelper(helper.path) }
        let container = temporaryRoot.appendingPathComponent(
            "swiftui-audit-index-helper-\(UUID().uuidString)", isDirectory: true
        )
        let requestURL = container.appendingPathComponent("request.json")
        let responseURL = container.appendingPathComponent("response.json")
        let databaseURL = try cache.map {
            try persistentDatabaseURL(cache: $0, store: store, library: library)
        } ?? container.appendingPathComponent("database", isDirectory: true)
        try fileManager.createDirectory(at: container, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: container) }
        let request = IndexEnrichmentRequest(
            sourceRoot: sourceRoot.standardizedFileURL.resolvingSymlinksInPath().path,
            indexStorePath: store.path,
            databasePath: databaseURL.path,
            indexStoreLibraryPath: library.path,
            cacheDirectory: cache?.projectDirectoryURL.path,
            graph: graph
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        try encoder.encode(request).write(to: requestURL, options: .atomic)
        let runHelper = {
            try runner.run(
                helper.path,
                arguments: ["_index-enrich", "--request", requestURL.path, "--response", responseURL.path],
                currentDirectory: nil,
                timeout: timeout
            )
        }
        let result: BoundedProcessResult
        if cache != nil {
            try fileManager.createDirectory(
                at: databaseURL.deletingLastPathComponent(), withIntermediateDirectories: true
            )
            result = try withDatabaseLock(
                at: databaseURL.appendingPathExtension("lock"),
                operation: runHelper
            )
        } else {
            result = try runHelper()
        }
        guard result.status == 0 else {
            throw IndexResolutionError.helperFailed(
                result.status,
                result.errorString.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }
        guard fileManager.fileExists(atPath: responseURL.path) else {
            throw IndexResolutionError.invalidResponse("helper produced no response")
        }
        let response: IndexEnrichmentResponse
        do {
            response = try JSONDecoder().decode(IndexEnrichmentResponse.self, from: Data(contentsOf: responseURL))
        } catch {
            throw IndexResolutionError.invalidResponse(error.localizedDescription)
        }
        guard response.mappedSymbols > 0 || response.indexedFacts > 0,
              response.graph.resolution == "indexed"
        else { throw IndexResolutionError.noProjectCoverage(store.path) }
        return response.graph
    }

    private func persistentDatabaseURL(cache: AnalysisCacheStore, store: URL, library: URL) throws -> URL {
        let libraryValues = try library.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
        let identity = [
            "cache:\(AnalysisCacheStore.schemaVersion)",
            "store:\(store.standardizedFileURL.resolvingSymlinksInPath().path)",
            "library:\(library.standardizedFileURL.resolvingSymlinksInPath().path)",
            "size:\(libraryValues.fileSize ?? 0)",
            "modified:\(libraryValues.contentModificationDate?.timeIntervalSince1970 ?? 0)",
        ].joined(separator: "|")
        return cache.projectDirectoryURL
            .appendingPathComponent("indexstoredb", isDirectory: true)
            .appendingPathComponent(AnalysisCacheStore.digest(Data(identity.utf8)), isDirectory: true)
    }

    private func withDatabaseLock<Value>(
        at lockURL: URL,
        operation: () throws -> Value
    ) throws -> Value {
        let descriptor = open(lockURL.path, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)
        guard descriptor >= 0 else {
            throw BoundedProcessError.launch("IndexStoreDB cache lock", String(cString: strerror(errno)))
        }
        defer { close(descriptor) }
        let deadline = Date().addingTimeInterval(timeout)
        while flock(descriptor, LOCK_EX | LOCK_NB) != 0 {
            guard errno == EWOULDBLOCK else {
                throw BoundedProcessError.launch("IndexStoreDB cache lock", String(cString: strerror(errno)))
            }
            guard Date() < deadline else {
                throw BoundedProcessError.timeout("IndexStoreDB cache lock", timeout)
            }
            usleep(50_000)
        }
        defer { flock(descriptor, LOCK_UN) }
        return try operation()
    }
}
