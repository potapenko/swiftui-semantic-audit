import AuditCore
import Foundation

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
        metadata: SliceMetadata
    ) {
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

    public var errorDescription: String? {
        switch self {
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
