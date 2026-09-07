import AuditCore
import CryptoKit
import Foundation
import SnapshotStore

public struct SliceProvenance: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let toolVersion: String
    /// Identifies full semantic evidence; not a hash of all source bytes.
    public let inputDigest: String
    public let snapshotManifest: SnapshotManifest?

    init(graph: SemanticGraph, report: AuditReport, manifest: SnapshotManifest?) throws {
        guard graph.schemaVersion == report.schemaVersion,
              graph.resolution == report.resolution,
              ["indexed", "syntax-only"].contains(graph.resolution),
              graph.configurationDigest == report.configurationDigest else {
            throw ContextSliceError.inconsistentInput("graph and report schema, resolution or configuration differ")
        }
        if let manifest {
            guard manifest.schemaVersion == graph.schemaVersion,
                  manifest.toolVersion == report.toolVersion,
                  manifest.configurationDigest == graph.configurationDigest else {
                throw ContextSliceError.inconsistentInput("snapshot manifest does not match graph and report")
            }
        }
        struct Input: Encodable {
            let graph: SemanticGraph
            let report: AuditReport
            let manifest: SnapshotManifest?
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(Input(graph: graph, report: report, manifest: manifest))
        schemaVersion = graph.schemaVersion
        toolVersion = report.toolVersion
        inputDigest = "sha256:" + SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        snapshotManifest = manifest
    }
}

public struct SliceMetadata: Codable, Equatable, Sendable {
    public let selection: String
    public let tokenBudget: Int?
    public let estimatedTokens: Int
    public let truncated: Bool

    public init(selection: String, tokenBudget: Int?, estimatedTokens: Int, truncated: Bool) {
        self.selection = selection
        self.tokenBudget = tokenBudget
        self.estimatedTokens = estimatedTokens
        self.truncated = truncated
    }
}

public struct ContextSlice: Codable, Equatable, Sendable {
    // Optional only for source compatibility and decoding legacy slices.
    // Every newly generated slice supplies these; absence means unknown.
    public let resolution: String?
    public let configurationDigest: String?
    public let provenance: SliceProvenance?
    public let finding: AuditFinding?
    public let semanticValues: [NormalizedSemanticValue]
    public let nodes: [SemanticNode]
    public let edges: [SemanticEdge]
    public let sourceEvidence: [Evidence]
    public let questions: [String]
    public let metadata: SliceMetadata

    public init(
        finding: AuditFinding?,
        semanticValues: [NormalizedSemanticValue],
        nodes: [SemanticNode],
        edges: [SemanticEdge],
        sourceEvidence: [Evidence],
        questions: [String],
        metadata: SliceMetadata,
        resolution: String? = nil,
        configurationDigest: String? = nil,
        provenance: SliceProvenance? = nil
    ) {
        self.resolution = resolution
        self.configurationDigest = configurationDigest
        self.provenance = provenance
        self.finding = finding
        self.semanticValues = semanticValues.sorted { $0.id < $1.id }
        self.nodes = nodes.sorted { $0.id < $1.id }
        self.edges = edges.sorted { $0.id < $1.id }
        self.sourceEvidence = Array(Set(sourceEvidence)).sorted(by: Evidence.canonicalOrder)
        self.questions = Array(Set(questions)).sorted()
        self.metadata = metadata
    }

    public func jsonData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        var data = try encoder.encode(self)
        data.append(0x0A)
        return data
    }
}

public enum ContextSliceError: Error, Equatable, LocalizedError {
    case unknownFinding(String)
    case unknownSymbol(String)
    case ambiguousSymbol(String, [String])
    case invalidBudget(Int)
    case insufficientBudget(requested: Int, minimum: Int)
    case inconsistentInput(String)

    public var errorDescription: String? {
        switch self {
        case .inconsistentInput(let detail):
            "inconsistent slice input: \(detail)"
        case .unknownFinding(let id):
            "unknown finding \(id)"
        case .unknownSymbol(let symbol):
            "unknown symbol \(symbol)"
        case .ambiguousSymbol(let symbol, let candidates):
            "ambiguous symbol \(symbol); candidates: \(candidates.joined(separator: ", "))"
        case .invalidBudget(let budget):
            "token budget must be positive, received \(budget)"
        case .insufficientBudget(let requested, let minimum):
            "token budget \(requested) cannot fit the mandatory slice envelope; minimum is \(minimum)"
        }
    }
}
