import AuditCore
import CryptoKit
import Foundation
import SwiftSyntaxFrontend

public struct AnalysisCacheStore: Sendable {
    public static let schemaVersion = 1

    public let projectDirectoryURL: URL

    public init(rootDirectory: URL? = nil, sourceRoot: URL) {
        let userCache = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let root = rootDirectory ?? userCache.appendingPathComponent("swiftui-audit", isDirectory: true)
        let canonicalSource = sourceRoot.standardizedFileURL.resolvingSymlinksInPath().path
        let projectKey = Self.digest(Data(canonicalSource.utf8))
        self.projectDirectoryURL = root
            .appendingPathComponent("v\(Self.schemaVersion)", isDirectory: true)
            .appendingPathComponent(projectKey, isDirectory: true)
    }

    public init(projectDirectoryURL: URL) {
        self.projectDirectoryURL = projectDirectoryURL.standardizedFileURL
    }

    public func loadFrontendState() -> FrontendCacheState? {
        decode(FrontendCacheState.self, from: projectDirectoryURL.appendingPathComponent("frontend.json"))
    }

    public func saveFrontendState(_ state: FrontendCacheState) throws {
        try encode(state, to: projectDirectoryURL.appendingPathComponent("frontend.json"))
    }

    public func loadIndexedGraph(key: String) -> SemanticGraph? {
        decode(SemanticGraph.self, from: indexedURL(key: key))
    }

    public func saveIndexedGraph(_ graph: SemanticGraph, key: String) throws {
        try encode(graph, to: indexedURL(key: key))
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
    }

    private func canonicalData<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(value)
    }
}

private struct CacheEnvelope<Payload: Codable>: Codable {
    let schemaVersion: Int
    let payloadDigest: String
    let payload: Payload
}
