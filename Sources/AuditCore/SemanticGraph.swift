import Foundation

public enum NodeKind: String, Codable, CaseIterable, Sendable {
    case module
    case type
    case view
    case function
    case closure
    case property
    case state
    case observableState
    case binding
    case input
    case callback
    case derivedValue
    case event
    case effect
    case semanticValue
}

public enum EdgeKind: String, Codable, CaseIterable, Sendable {
    case owns
    case reads
    case writes
    case binds
    case observes
    case injects
    case passes
    case calls
    case sets
    case copiesTo
    case derivesFrom
    case triggers
    case aliases
    case creates
}

public enum Confidence: String, Codable, CaseIterable, Sendable {
    case deterministic
    case strongInference = "strong-inference"
    case candidate
    case llmInferred = "llm-inferred"
}

public struct Evidence: Codable, Hashable, Sendable {
    public let file: String
    public let startLine: Int
    public let endLine: Int
    public let kind: String

    public init(file: String, startLine: Int, endLine: Int, kind: String) {
        self.file = file
        self.startLine = startLine
        self.endLine = endLine
        self.kind = kind
    }
}

public struct SemanticNode: Codable, Hashable, Sendable {
    public let id: String
    public let kind: NodeKind
    public let name: String
    public let qualifiedName: String
    public let evidence: [Evidence]
    public let confidence: Confidence

    public init(
        id: String,
        kind: NodeKind,
        name: String,
        qualifiedName: String,
        evidence: [Evidence],
        confidence: Confidence = .deterministic
    ) {
        self.id = id
        self.kind = kind
        self.name = name
        self.qualifiedName = qualifiedName
        self.evidence = evidence
        self.confidence = confidence
    }
}

public struct SemanticEdge: Codable, Hashable, Sendable {
    public let id: String
    public let kind: EdgeKind
    public let from: String
    public let to: String
    public let evidence: [Evidence]
    public let confidence: Confidence

    public init(
        id: String,
        kind: EdgeKind,
        from: String,
        to: String,
        evidence: [Evidence],
        confidence: Confidence
    ) {
        self.id = id
        self.kind = kind
        self.from = from
        self.to = to
        self.evidence = evidence
        self.confidence = confidence
    }
}

public struct SemanticGraph: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let resolution: String
    public let nodes: [SemanticNode]
    public let edges: [SemanticEdge]

    public init(schemaVersion: Int = 1, resolution: String = "syntax-only", nodes: [SemanticNode], edges: [SemanticEdge]) {
        self.schemaVersion = schemaVersion
        self.resolution = resolution
        self.nodes = nodes.sorted(by: SemanticNode.canonicalOrder)
        self.edges = edges.sorted(by: SemanticEdge.canonicalOrder)
    }

    public func jsonData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        var data = try encoder.encode(self)
        data.append(0x0A)
        return data
    }
}

public enum StableID {
    public static func node(module: String, qualifiedName: String, kind: NodeKind, discriminator: String = "declaration") -> String {
        make(prefix: "node", components: [module, qualifiedName, kind.rawValue, discriminator])
    }

    public static func edge(kind: EdgeKind, from: String, to: String, discriminator: String) -> String {
        make(prefix: "edge", components: [kind.rawValue, from, to, discriminator])
    }

    public static func finding(rule: String, nodes: [String], edges: [String], discriminator: String = "") -> String {
        make(prefix: "finding", components: [rule, nodes.sorted().joined(separator: ","), edges.sorted().joined(separator: ","), discriminator])
    }

    public static func semanticValue(representations: [String]) -> String {
        make(prefix: "value", components: [representations.sorted().joined(separator: ",")])
    }

    private static func make(prefix: String, components: [String]) -> String {
        let identity = components.joined(separator: "\u{1F}")
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in identity.utf8 {
            hash ^= UInt64(byte)
            hash &*= 0x100000001b3
        }
        return "\(prefix):\(String(hash, radix: 16, uppercase: false))"
    }
}

private extension SemanticNode {
    static func canonicalOrder(_ lhs: SemanticNode, _ rhs: SemanticNode) -> Bool {
        (lhs.id, lhs.kind.rawValue, lhs.qualifiedName) < (rhs.id, rhs.kind.rawValue, rhs.qualifiedName)
    }
}

private extension SemanticEdge {
    static func canonicalOrder(_ lhs: SemanticEdge, _ rhs: SemanticEdge) -> Bool {
        (lhs.id, lhs.kind.rawValue, lhs.from, lhs.to) < (rhs.id, rhs.kind.rawValue, rhs.from, rhs.to)
    }
}
