import AuditCore
import Foundation

public enum SemanticChangeKind: String, Codable, CaseIterable, Sendable {
    case nodeAdded = "NODE_ADDED"
    case nodeRemoved = "NODE_REMOVED"
    case ownershipChanged = "OWNERSHIP_CHANGED"
    case readPathAdded = "READ_PATH_ADDED"
    case readPathRemoved = "READ_PATH_REMOVED"
    case writePathAdded = "WRITE_PATH_ADDED"
    case writePathRemoved = "WRITE_PATH_REMOVED"
    case bindingAdded = "BINDING_ADDED"
    case bindingRemoved = "BINDING_REMOVED"
    case manualSyncAdded = "MANUAL_SYNC_ADDED"
    case manualSyncRemoved = "MANUAL_SYNC_REMOVED"
    case derivationChanged = "DERIVATION_CHANGED"
    case sourceOfTruthCountChanged = "SOURCE_OF_TRUTH_COUNT_CHANGED"
}

public struct SemanticChange: Codable, Equatable, Sendable {
    public let id: String
    public let kind: SemanticChangeKind
    public let nodes: [String]
    public let beforeEdges: [String]
    public let afterEdges: [String]
    public let semanticValues: [String]
    public let before: String?
    public let after: String?

    public init(
        kind: SemanticChangeKind,
        nodes: [String] = [],
        beforeEdges: [String] = [],
        afterEdges: [String] = [],
        semanticValues: [String] = [],
        before: String? = nil,
        after: String? = nil
    ) {
        self.kind = kind
        self.nodes = Array(Set(nodes)).sorted()
        self.beforeEdges = Array(Set(beforeEdges)).sorted()
        self.afterEdges = Array(Set(afterEdges)).sorted()
        self.semanticValues = Array(Set(semanticValues)).sorted()
        self.before = before
        self.after = after
        self.id = DiffStableID.make(
            prefix: "change",
            components: [
                kind.rawValue,
                self.nodes.joined(separator: ","),
                self.beforeEdges.joined(separator: ","),
                self.afterEdges.joined(separator: ","),
                self.semanticValues.joined(separator: ","),
                before ?? "",
                after ?? "",
            ]
        )
    }
}

public struct SemanticValueDelta: Codable, Equatable, Sendable {
    public let id: String
    public let beforeRepresentations: [String]
    public let afterRepresentations: [String]
    public let beforeRepresentationCount: Int?
    public let afterRepresentationCount: Int?
    public let beforeSourceCount: Int?
    public let afterSourceCount: Int?

    public init(
        id: String,
        beforeRepresentations: [String],
        afterRepresentations: [String],
        beforeRepresentationCount: Int?,
        afterRepresentationCount: Int?,
        beforeSourceCount: Int?,
        afterSourceCount: Int?
    ) {
        self.id = id
        self.beforeRepresentations = beforeRepresentations.sorted()
        self.afterRepresentations = afterRepresentations.sorted()
        self.beforeRepresentationCount = beforeRepresentationCount
        self.afterRepresentationCount = afterRepresentationCount
        self.beforeSourceCount = beforeSourceCount
        self.afterSourceCount = afterSourceCount
    }
}

public struct SemanticDiffReport: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let toolVersion: String
    public let baseIdentity: String
    public let currentIdentity: String
    public let beforeMetrics: AuditMetrics
    public let afterMetrics: AuditMetrics
    public let changes: [SemanticChange]
    public let newFindings: [AuditFinding]
    public let resolvedFindings: [AuditFinding]
    public let affectedSemanticValues: [SemanticValueDelta]

    public init(
        schemaVersion: Int = ToolMetadata.schemaVersion,
        toolVersion: String = ToolMetadata.version,
        baseIdentity: String,
        currentIdentity: String,
        beforeMetrics: AuditMetrics,
        afterMetrics: AuditMetrics,
        changes: [SemanticChange],
        newFindings: [AuditFinding],
        resolvedFindings: [AuditFinding],
        affectedSemanticValues: [SemanticValueDelta]
    ) {
        self.schemaVersion = schemaVersion
        self.toolVersion = toolVersion
        self.baseIdentity = baseIdentity
        self.currentIdentity = currentIdentity
        self.beforeMetrics = beforeMetrics
        self.afterMetrics = afterMetrics
        var changesByID: [String: SemanticChange] = [:]
        for change in changes { changesByID[change.id] = change }
        self.changes = changesByID.values.sorted { ($0.kind.rawValue, $0.id) < ($1.kind.rawValue, $1.id) }
        self.newFindings = newFindings.sorted { ($0.rule.rawValue, $0.id) < ($1.rule.rawValue, $1.id) }
        self.resolvedFindings = resolvedFindings.sorted { ($0.rule.rawValue, $0.id) < ($1.rule.rawValue, $1.id) }
        self.affectedSemanticValues = affectedSemanticValues.sorted { $0.id < $1.id }
    }

    public func jsonData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        var data = try encoder.encode(self)
        data.append(0x0A)
        return data
    }
}

public struct CheckReport: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let baselineIdentity: String
    public let currentIdentity: String
    public let threshold: Severity
    public let passed: Bool
    public let totalNewFindings: Int
    public let failingFindings: [AuditFinding]

    public init(diff: SemanticDiffReport, threshold: Severity) {
        self.schemaVersion = ToolMetadata.schemaVersion
        self.baselineIdentity = diff.baseIdentity
        self.currentIdentity = diff.currentIdentity
        self.threshold = threshold
        self.totalNewFindings = diff.newFindings.count
        self.failingFindings = diff.newFindings.filter { $0.severity.rank >= threshold.rank }
            .sorted { ($0.severity.rank, $0.rule.rawValue, $0.id) > ($1.severity.rank, $1.rule.rawValue, $1.id) }
        self.passed = failingFindings.isEmpty
    }

    public func jsonData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        var data = try encoder.encode(self)
        data.append(0x0A)
        return data
    }
}

public extension Severity {
    var rank: Int {
        switch self {
        case .low: 0
        case .medium: 1
        case .high: 2
        }
    }
}

enum DiffStableID {
    static func make(prefix: String, components: [String]) -> String {
        let identity = components.joined(separator: "\u{1F}")
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in identity.utf8 {
            hash ^= UInt64(byte)
            hash &*= 0x100000001b3
        }
        return "\(prefix):\(String(hash, radix: 16, uppercase: false))"
    }
}
