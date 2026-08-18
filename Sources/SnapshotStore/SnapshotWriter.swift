import AuditCore
import Foundation

public struct SnapshotWriter: Sendable {
    public static let requiredFiles = [
        "manifest.json", "nodes.jsonl", "edges.jsonl", "findings.jsonl", "summary.json",
    ]

    public init() {}

    public func write(
        graph: SemanticGraph,
        report: AuditReport,
        manifest: SnapshotManifest,
        sourceURL: URL,
        to outputURL: URL
    ) throws {
        let canonicalGraph = SemanticGraph(
            schemaVersion: graph.schemaVersion,
            resolution: graph.resolution,
            configurationDigest: graph.configurationDigest,
            nodes: graph.nodes.map {
                SemanticNode(
                    id: $0.id,
                    kind: $0.kind,
                    name: $0.name,
                    qualifiedName: $0.qualifiedName,
                    evidence: Array(Set($0.evidence)).sorted(by: Evidence.canonicalOrder),
                    confidence: $0.confidence,
                    roles: $0.roles,
                    feature: $0.feature
                )
            },
            edges: graph.edges.map {
                SemanticEdge(
                    id: $0.id,
                    kind: $0.kind,
                    from: $0.from,
                    to: $0.to,
                    evidence: Array(Set($0.evidence)).sorted(by: Evidence.canonicalOrder),
                    confidence: $0.confidence
                )
            }
        )
        try SnapshotValidator.validate(graph: canonicalGraph, report: report, manifest: manifest)
        let locations = try SnapshotPathPolicy.validate(sourceURL: sourceURL, outputURL: outputURL)
        let output = locations.output
        let parent = output.deletingLastPathComponent()
        let operationID = UUID().uuidString
        let staging = parent.appendingPathComponent(".\(output.lastPathComponent).writing-\(operationID)", isDirectory: true)
        let backup = parent.appendingPathComponent(".\(output.lastPathComponent).previous-\(operationID)", isDirectory: true)
        let fileManager = FileManager.default

        try Self.validateExistingOutput(at: output)
        try fileManager.createDirectory(at: parent, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: staging, withIntermediateDirectories: true)

        do {
            try Self.canonicalJSON(manifest).write(
                to: staging.appendingPathComponent("manifest.json"), options: .atomic
            )
            try Self.jsonLines(canonicalGraph.nodes.sorted { $0.id < $1.id }).write(
                to: staging.appendingPathComponent("nodes.jsonl"), options: .atomic
            )
            try Self.jsonLines(canonicalGraph.edges.sorted { $0.id < $1.id }).write(
                to: staging.appendingPathComponent("edges.jsonl"), options: .atomic
            )
            try Self.jsonLines(report.findings.sorted { $0.id < $1.id }.map(CanonicalFinding.init)).write(
                to: staging.appendingPathComponent("findings.jsonl"), options: .atomic
            )
            try Self.canonicalJSON(SnapshotSummary(graph: canonicalGraph, report: report)).write(
                to: staging.appendingPathComponent("summary.json"), options: .atomic
            )

            try Self.validateExistingOutput(at: output)
            if fileManager.fileExists(atPath: output.path) {
                try fileManager.moveItem(at: output, to: backup)
            }
            do {
                try fileManager.moveItem(at: staging, to: output)
                if fileManager.fileExists(atPath: backup.path) { try fileManager.removeItem(at: backup) }
            } catch {
                if !fileManager.fileExists(atPath: output.path), fileManager.fileExists(atPath: backup.path) {
                    try? fileManager.moveItem(at: backup, to: output)
                }
                throw error
            }
        } catch {
            if fileManager.fileExists(atPath: staging.path) { try? fileManager.removeItem(at: staging) }
            throw error
        }
    }

    static func canonicalJSON<T: Encodable>(_ value: T) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        var data = try encoder.encode(value)
        data.append(0x0A)
        return data
    }

    static func jsonLines<T: Encodable>(_ values: [T]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        var result = Data()
        for value in values {
            result.append(try encoder.encode(value))
            result.append(0x0A)
        }
        return result
    }

    private static func validateExistingOutput(at output: URL) throws {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: output.path, isDirectory: &isDirectory) else { return }
        guard isDirectory.boolValue else {
            throw SnapshotError.existingOutputNotSnapshot(output.path, "path is not a directory")
        }
        let entries: [String]
        do {
            entries = try fileManager.contentsOfDirectory(atPath: output.path)
        } catch {
            throw SnapshotError.existingOutputNotSnapshot(output.path, error.localizedDescription)
        }
        if entries.isEmpty { return }
        do {
            _ = try SnapshotReader().read(from: output)
        } catch {
            throw SnapshotError.existingOutputNotSnapshot(output.path, error.localizedDescription)
        }
    }
}

private struct CanonicalFinding: Encodable {
    let id: String
    let rule: RuleID
    let severity: Severity
    let confidence: Confidence
    let nodes: [String]
    let edges: [String]
    let evidence: [Evidence]
    let suggestedPatterns: [String]
    let depth: Int?

    init(_ finding: AuditFinding) {
        self.id = finding.id
        self.rule = finding.rule
        self.severity = finding.severity
        self.confidence = finding.confidence
        self.nodes = Array(Set(finding.nodes)).sorted()
        self.edges = Array(Set(finding.edges)).sorted()
        self.evidence = Array(Set(finding.evidence)).sorted(by: Evidence.canonicalOrder)
        self.suggestedPatterns = Array(Set(finding.suggestedPatterns)).sorted()
        self.depth = finding.depth
    }
}

enum SnapshotValidator {
    static func validate(graph: SemanticGraph, report: AuditReport, manifest: SnapshotManifest) throws {
        guard manifest.schemaVersion == ToolMetadata.schemaVersion else {
            throw SnapshotError.unsupportedSchema(manifest.schemaVersion)
        }
        guard graph.schemaVersion == manifest.schemaVersion else {
            throw SnapshotError.inconsistentSchema(graph.schemaVersion, manifest.schemaVersion)
        }
        guard graph.resolution == report.resolution else {
            throw SnapshotError.inconsistentResolution(graph.resolution, report.resolution)
        }
        guard graph.configurationDigest == report.configurationDigest,
              graph.configurationDigest == manifest.configurationDigest else {
            throw SnapshotError.malformedFile("manifest.json", "configuration digest mismatch")
        }
        if manifest.generatedFrom.hasPrefix("/") { throw SnapshotError.absolutePath(manifest.generatedFrom) }

        let nodeIDs = try uniqueIDs(graph.nodes.map(\.id), file: "nodes.jsonl")
        let edgeIDs = try uniqueIDs(graph.edges.map(\.id), file: "edges.jsonl")
        _ = try uniqueIDs(report.findings.map(\.id), file: "findings.jsonl")
        for node in graph.nodes { try validateEvidence(node.evidence) }
        for edge in graph.edges {
            if !nodeIDs.contains(edge.from) { throw SnapshotError.danglingEdge(edge.id, edge.from) }
            if !nodeIDs.contains(edge.to) { throw SnapshotError.danglingEdge(edge.id, edge.to) }
            try validateEvidence(edge.evidence)
        }
        for finding in report.findings {
            for id in finding.nodes where !nodeIDs.contains(id) {
                throw SnapshotError.danglingFindingReference(finding.id, id)
            }
            for id in finding.edges where !edgeIDs.contains(id) {
                throw SnapshotError.danglingFindingReference(finding.id, id)
            }
            try validateEvidence(finding.evidence)
        }
        for value in report.semanticValues {
            for id in value.representations where !nodeIDs.contains(id) {
                throw SnapshotError.danglingSemanticValueReference(value.id, id)
            }
            for id in value.relationEdges where !edgeIDs.contains(id) {
                throw SnapshotError.danglingSemanticValueReference(value.id, id)
            }
            try validateEvidence(value.evidence)
        }
    }

    static func uniqueIDs(_ ids: [String], file: String) throws -> Set<String> {
        var seen: Set<String> = []
        for id in ids where !seen.insert(id).inserted { throw SnapshotError.duplicateID(file, id) }
        return seen
    }

    static func validateEvidence(_ evidence: [Evidence]) throws {
        for item in evidence where item.file.hasPrefix("/") { throw SnapshotError.absolutePath(item.file) }
    }
}
