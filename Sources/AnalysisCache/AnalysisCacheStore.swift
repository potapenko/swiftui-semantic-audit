import AuditCore
import CryptoKit
import Foundation
import SwiftSyntaxFrontend

public struct AnalysisCacheStore: Sendable {
    public static let schemaVersion = 2
    public static let maximumSizeBytes: Int64 = 2 * 1_024 * 1_024 * 1_024
    public static let targetSizeBytes: Int64 = 1_536 * 1_024 * 1_024
    public static let indexedGraphRetentionCount = 2

    public let cacheRootURL: URL
    public let versionDirectoryURL: URL
    public let projectDirectoryURL: URL

    public init(rootDirectory: URL? = nil, sourceRoot: URL) {
        let userCache = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let root = (rootDirectory ?? userCache.appendingPathComponent("swiftui-audit", isDirectory: true))
            .standardizedFileURL
        let canonicalSource = sourceRoot.standardizedFileURL.resolvingSymlinksInPath().path
        let projectKey = Self.digest(Data(canonicalSource.utf8))
        self.cacheRootURL = root
        self.versionDirectoryURL = root.appendingPathComponent("v\(Self.schemaVersion)", isDirectory: true)
        self.projectDirectoryURL = versionDirectoryURL
            .appendingPathComponent("scopes", isDirectory: true)
            .appendingPathComponent(projectKey, isDirectory: true)
    }

    public init(projectDirectoryURL: URL) {
        let project = projectDirectoryURL.standardizedFileURL
        self.projectDirectoryURL = project
        if project.deletingLastPathComponent().lastPathComponent == "scopes" {
            self.versionDirectoryURL = project.deletingLastPathComponent().deletingLastPathComponent()
            self.cacheRootURL = versionDirectoryURL.deletingLastPathComponent()
        } else {
            self.versionDirectoryURL = project.deletingLastPathComponent()
            self.cacheRootURL = versionDirectoryURL.deletingLastPathComponent()
        }
    }

    public var sharedIndexStoreRootURL: URL {
        versionDirectoryURL
            .appendingPathComponent("shared", isDirectory: true)
            .appendingPathComponent("indexstoredb", isDirectory: true)
    }

    public func loadFrontendState() -> FrontendCacheState? {
        decode(FrontendCacheState.self, from: projectDirectoryURL.appendingPathComponent("frontend.json"))
    }

    public func saveFrontendState(_ state: FrontendCacheState) throws {
        try encode(state, to: projectDirectoryURL.appendingPathComponent("frontend.json"))
    }

    public func loadIndexedGraph(key: String) -> SemanticGraph? {
        let url = indexedURL(key: key)
        guard let graph = decode(SemanticGraph.self, from: url) else { return nil }
        recordSuccessfulIndexedUse(protecting: url)
        return graph
    }

    public func saveIndexedGraph(_ graph: SemanticGraph, key: String) throws {
        let url = indexedURL(key: key)
        try encode(graph, to: url)
        try? retainRecentIndexedGraphs(protecting: url)
        recordSuccessfulIndexedUse(protecting: url)
    }

    public func sharedIndexStoreDatabaseURL(identityData: Data) -> URL {
        sharedIndexStoreRootURL.appendingPathComponent(Self.digest(identityData), isDirectory: true)
    }

    public func markSharedIndexStoreDatabaseUsed(_ databaseURL: URL) {
        let canonicalDatabase = databaseURL.standardizedFileURL
        let prefix = sharedIndexStoreRootURL.standardizedFileURL.path + "/"
        guard canonicalDatabase.path.hasPrefix(prefix),
              canonicalDatabase.deletingLastPathComponent() == sharedIndexStoreRootURL.standardizedFileURL
        else { return }
        let accessURL = canonicalDatabase.appendingPathExtension("access")
        try? touch(accessURL)
    }

    public func loadArtifact<T: Codable>(_ type: T.Type, namespace: String, key: String) -> T? {
        guard Self.safeComponent(namespace), Self.safeComponent(key) else { return nil }
        return decode(type, from: artifactURL(namespace: namespace, key: key))
    }

    public func saveArtifact<T: Codable>(_ value: T, namespace: String, key: String) throws {
        guard Self.safeComponent(namespace), Self.safeComponent(key) else {
            throw CocoaError(.fileWriteInvalidFileName)
        }
        try encode(value, to: artifactURL(namespace: namespace, key: key))
    }

    public static func digest(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private func indexedURL(key: String) -> URL {
        projectDirectoryURL
            .appendingPathComponent("indexed", isDirectory: true)
            .appendingPathComponent("\(key).json")
    }

    private func artifactURL(namespace: String, key: String) -> URL {
        projectDirectoryURL
            .appendingPathComponent(namespace, isDirectory: true)
            .appendingPathComponent("\(key).json")
    }

    private static func safeComponent(_ value: String) -> Bool {
        !value.isEmpty && value.allSatisfy { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
    }

    private func decode<T: Codable>(_ type: T.Type, from url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        guard let envelope = try? JSONDecoder().decode(CacheEnvelope<T>.self, from: data),
              envelope.schemaVersion == Self.schemaVersion,
              let payload = try? canonicalData(envelope.payload),
              Self.digest(payload) == envelope.payloadDigest
        else { return nil }
        try? touch(url)
        try? touch(projectDirectoryURL.appendingPathComponent(".access"))
        return envelope.payload
    }

    private func encode<T: Codable>(_ value: T, to url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        let payload = try canonicalData(value)
        let envelope = CacheEnvelope(
            schemaVersion: Self.schemaVersion,
            payloadDigest: Self.digest(payload),
            payload: value
        )
        try canonicalData(envelope).write(to: url, options: .atomic)
        try? touch(projectDirectoryURL.appendingPathComponent(".access"))
    }

    private func canonicalData<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(value)
    }

    private func retainRecentIndexedGraphs(protecting protectedURL: URL) throws {
        let directory = projectDirectoryURL.appendingPathComponent("indexed", isDirectory: true)
        let files = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ).filter {
            $0.pathExtension == "json" &&
                (try? $0.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true
        }.sorted {
            let lhsProtected = $0.standardizedFileURL.path == protectedURL.standardizedFileURL.path
            let rhsProtected = $1.standardizedFileURL.path == protectedURL.standardizedFileURL.path
            if lhsProtected != rhsProtected { return lhsProtected }
            let lhs = (try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate)
                ?? .distantPast
            let rhs = (try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate)
                ?? .distantPast
            return (lhs, $0.lastPathComponent) > (rhs, $1.lastPathComponent)
        }
        for file in files.dropFirst(Self.indexedGraphRetentionCount) {
            try? FileManager.default.removeItem(at: file)
        }
    }

    private func recordSuccessfulIndexedUse(protecting protectedURL: URL) {
        try? FileManager.default.createDirectory(at: versionDirectoryURL, withIntermediateDirectories: true)
        let firstSuccess = versionDirectoryURL.appendingPathComponent(".first-success")
        if !FileManager.default.fileExists(atPath: firstSuccess.path) {
            _ = FileManager.default.createFile(atPath: firstSuccess.path, contents: Data())
        }
        _ = try? performMaintenance(protecting: [protectedURL])
    }

    func touch(_ url: URL, at date: Date = Date()) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        if !FileManager.default.fileExists(atPath: url.path) {
            _ = FileManager.default.createFile(atPath: url.path, contents: Data())
        }
        try FileManager.default.setAttributes([.modificationDate: date], ofItemAtPath: url.path)
    }
}

private struct CacheEnvelope<Payload: Codable>: Codable {
    let schemaVersion: Int
    let payloadDigest: String
    let payload: Payload
}
