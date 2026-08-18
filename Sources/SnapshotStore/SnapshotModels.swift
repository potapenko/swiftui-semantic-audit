import AuditCore
import Foundation

public struct SnapshotManifest: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let toolVersion: String
    public let swiftVersion: String
    public let repositoryRevision: String
    public let generatedFrom: String
    public let configurationDigest: String

    public init(
        schemaVersion: Int = ToolMetadata.schemaVersion,
        toolVersion: String = ToolMetadata.version,
        swiftVersion: String,
        repositoryRevision: String,
        generatedFrom: String,
        configurationDigest: String = "none"
    ) {
        self.schemaVersion = schemaVersion
        self.toolVersion = toolVersion
        self.swiftVersion = swiftVersion
        self.repositoryRevision = repositoryRevision
        self.generatedFrom = generatedFrom
        self.configurationDigest = configurationDigest
    }
}

public struct SnapshotSummary: Codable, Equatable, Sendable {
    public let resolution: String
    public let nodeCount: Int
    public let edgeCount: Int
    public let findingCount: Int
    public let metrics: AuditMetrics
    public let semanticValues: [NormalizedSemanticValue]

    public init(graph: SemanticGraph, report: AuditReport) {
        self.resolution = graph.resolution
        self.nodeCount = graph.nodes.count
        self.edgeCount = graph.edges.count
        self.findingCount = report.findings.count
        self.metrics = report.metrics
        self.semanticValues = report.semanticValues.map {
            NormalizedSemanticValue(
                id: $0.id,
                representations: $0.representations,
                relationEdges: $0.relationEdges,
                confidence: $0.confidence,
                classification: $0.classification,
                evidence: $0.evidence
            )
        }.sorted { $0.id < $1.id }
    }
}

public struct SemanticSnapshot: Equatable, Sendable {
    public let manifest: SnapshotManifest
    public let graph: SemanticGraph
    public let report: AuditReport

    public init(manifest: SnapshotManifest, graph: SemanticGraph, report: AuditReport) {
        self.manifest = manifest
        self.graph = graph
        self.report = report
    }
}

public enum SnapshotError: Error, Equatable, LocalizedError {
    case missingFile(String)
    case unsupportedSchema(Int)
    case malformedFile(String, String)
    case malformedLine(String, Int, String)
    case duplicateID(String, String)
    case unsortedIDs(String)
    case danglingEdge(String, String)
    case danglingFindingReference(String, String)
    case danglingSemanticValueReference(String, String)
    case countMismatch(String, expected: Int, actual: Int)
    case absolutePath(String)
    case inconsistentResolution(String, String)
    case inconsistentSchema(Int, Int)
    case unsafeOutputPath(String)
    case sourceOutputOverlap(source: String, output: String)
    case existingOutputNotSnapshot(String, String)
    case incompleteSnapshot([String])
    case unexpectedEntries([String])
    case nonRegularEntry(String)

    public var errorDescription: String? {
        switch self {
        case .missingFile(let file):
            "snapshot is missing required file \(file)"
        case .unsupportedSchema(let version):
            "unsupported snapshot schema version \(version)"
        case .malformedFile(let file, let detail):
            "malformed snapshot file \(file): \(detail)"
        case .malformedLine(let file, let line, let detail):
            "malformed \(file) line \(line): \(detail)"
        case .duplicateID(let file, let id):
            "duplicate ID \(id) in \(file)"
        case .unsortedIDs(let file):
            "IDs in \(file) are not in canonical order"
        case .danglingEdge(let edge, let node):
            "edge \(edge) references missing node \(node)"
        case .danglingFindingReference(let finding, let reference):
            "finding \(finding) references missing graph ID \(reference)"
        case .danglingSemanticValueReference(let value, let reference):
            "semantic value \(value) references missing graph ID \(reference)"
        case .countMismatch(let kind, let expected, let actual):
            "snapshot \(kind) count mismatch: expected \(expected), found \(actual)"
        case .absolutePath(let path):
            "canonical snapshot contains absolute path \(path)"
        case .inconsistentResolution(let graph, let report):
            "snapshot resolution mismatch: graph \(graph), report \(report)"
        case .inconsistentSchema(let graph, let manifest):
            "snapshot schema mismatch: graph \(graph), manifest \(manifest)"
        case .unsafeOutputPath(let path):
            "snapshot output path is unsafe: \(path)"
        case .sourceOutputOverlap(let source, let output):
            "snapshot output overlaps source: source \(source), output \(output)"
        case .existingOutputNotSnapshot(let path, let detail):
            "existing snapshot output \(path) is not empty or a valid snapshot: \(detail)"
        case .incompleteSnapshot(let missing):
            "incomplete snapshot; missing files: \(missing.sorted().joined(separator: ", "))"
        case .unexpectedEntries(let entries):
            "snapshot contains unexpected entries: \(entries.sorted().joined(separator: ", "))"
        case .nonRegularEntry(let entry):
            "snapshot entry is not a regular file: \(entry)"
        }
    }
}
