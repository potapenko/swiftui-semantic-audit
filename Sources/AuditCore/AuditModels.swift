import Foundation

public enum RuleID: String, Codable, CaseIterable, Sendable {
    case mirroredState = "mirrored-state"
    case manualTwoWaySync = "manual-two-way-sync"
    case valueSetterPair = "value-setter-pair"
    case callbackBindingTunnel = "callback-binding-tunnel"
    case observableStateMirror = "observable-state-mirror"
    case storedDerivedState = "stored-derived-state"
}

public enum Severity: String, Codable, CaseIterable, Sendable {
    case low
    case medium
    case high
}

public enum SemanticClassification: String, Codable, Sendable {
    case transactionalDraft = "transactional-draft"
}

public struct NormalizedSemanticValue: Codable, Equatable, Sendable {
    public let id: String
    public let representations: [String]
    public let relationEdges: [String]
    public let confidence: Confidence
    public let classification: SemanticClassification?
    public let evidence: [Evidence]

    public init(
        id: String,
        representations: [String],
        relationEdges: [String],
        confidence: Confidence,
        classification: SemanticClassification?,
        evidence: [Evidence]
    ) {
        self.id = id
        self.representations = representations.sorted()
        self.relationEdges = Array(Set(relationEdges)).sorted()
        self.confidence = confidence
        self.classification = classification
        self.evidence = Array(Set(evidence)).sorted(by: Evidence.canonicalOrder)
    }
}

public struct AuditFinding: Codable, Equatable, Sendable {
    public let id: String
    public let rule: RuleID
    public let severity: Severity
    public let confidence: Confidence
    public let nodes: [String]
    public let edges: [String]
    public let evidence: [Evidence]
    public let suggestedPatterns: [String]
    public let depth: Int?

    public init(
        rule: RuleID,
        severity: Severity,
        confidence: Confidence,
        nodes: [String],
        edges: [String],
        evidence: [Evidence],
        suggestedPatterns: [String],
        depth: Int? = nil,
        discriminator: String = ""
    ) {
        let canonicalNodes = Array(Set(nodes)).sorted()
        let canonicalEdges = Array(Set(edges)).sorted()
        self.id = StableID.finding(
            rule: rule.rawValue,
            nodes: canonicalNodes,
            edges: canonicalEdges,
            discriminator: discriminator
        )
        self.rule = rule
        self.severity = severity
        self.confidence = confidence
        self.nodes = canonicalNodes
        self.edges = canonicalEdges
        self.evidence = Array(Set(evidence)).sorted(by: Evidence.canonicalOrder)
        self.suggestedPatterns = Array(Set(suggestedPatterns)).sorted()
        self.depth = depth
    }
}

public struct AuditMetrics: Codable, Equatable, Sendable {
    public let mutableSemanticValues: Int
    public let stateRepresentations: Int
    public let bindingEdges: Int
    public let manualSynchronizationEdges: Int
    public let callbackTunnels: Int
    public let derivedMutableValues: Int
    public let duplicatedSourcesOfTruth: Int
    public let ownershipViolations: Int

    public init(
        mutableSemanticValues: Int,
        stateRepresentations: Int,
        bindingEdges: Int,
        manualSynchronizationEdges: Int,
        callbackTunnels: Int,
        derivedMutableValues: Int,
        duplicatedSourcesOfTruth: Int,
        ownershipViolations: Int
    ) {
        self.mutableSemanticValues = mutableSemanticValues
        self.stateRepresentations = stateRepresentations
        self.bindingEdges = bindingEdges
        self.manualSynchronizationEdges = manualSynchronizationEdges
        self.callbackTunnels = callbackTunnels
        self.derivedMutableValues = derivedMutableValues
        self.duplicatedSourcesOfTruth = duplicatedSourcesOfTruth
        self.ownershipViolations = ownershipViolations
    }
}

public struct AuditReport: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let toolVersion: String
    public let resolution: String
    public let metrics: AuditMetrics
    public let semanticValues: [NormalizedSemanticValue]
    public let findings: [AuditFinding]

    public init(
        schemaVersion: Int = 1,
        toolVersion: String = "0.1.0",
        resolution: String,
        metrics: AuditMetrics,
        semanticValues: [NormalizedSemanticValue],
        findings: [AuditFinding]
    ) {
        self.schemaVersion = schemaVersion
        self.toolVersion = toolVersion
        self.resolution = resolution
        self.metrics = metrics
        self.semanticValues = semanticValues.sorted { $0.id < $1.id }
        self.findings = findings.sorted {
            ($0.rule.rawValue, $0.id) < ($1.rule.rawValue, $1.id)
        }
    }

    public func jsonData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        var data = try encoder.encode(self)
        data.append(0x0A)
        return data
    }
}

public extension Evidence {
    static func canonicalOrder(_ lhs: Evidence, _ rhs: Evidence) -> Bool {
        (lhs.file, lhs.startLine, lhs.endLine, lhs.kind) < (rhs.file, rhs.startLine, rhs.endLine, rhs.kind)
    }
}
