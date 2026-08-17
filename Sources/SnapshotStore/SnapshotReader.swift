import AuditCore
import Foundation

public struct SnapshotReader: Sendable {
    public init() {}

    public func read(from directoryURL: URL) throws -> SemanticSnapshot {
        let directory = SnapshotPathPolicy.canonicalURL(directoryURL)
        let fileManager = FileManager.default
        let entries: [URL]
        do {
            entries = try fileManager.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey],
                options: []
            )
        } catch {
            throw SnapshotError.malformedFile(directory.lastPathComponent, error.localizedDescription)
        }
        let names = entries.map(\.lastPathComponent).sorted()
        let required = SnapshotWriter.requiredFiles.sorted()
        let missing = required.filter { !names.contains($0) }
        if !missing.isEmpty { throw SnapshotError.incompleteSnapshot(missing) }
        let unexpected = names.filter { !required.contains($0) }
        if !unexpected.isEmpty { throw SnapshotError.unexpectedEntries(unexpected) }
        for entry in entries.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            let values = try entry.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey])
            if values.isRegularFile != true || values.isSymbolicLink == true {
                throw SnapshotError.nonRegularEntry(entry.lastPathComponent)
            }
        }

        let manifest: SnapshotManifest = try decodeJSON("manifest.json", in: directory)
        guard manifest.schemaVersion == 1 else { throw SnapshotError.unsupportedSchema(manifest.schemaVersion) }
        let summary: SnapshotSummary = try decodeJSON("summary.json", in: directory)
        let nodes: [SemanticNode] = try decodeLines("nodes.jsonl", in: directory)
        let edges: [SemanticEdge] = try decodeLines("edges.jsonl", in: directory)
        let findings: [AuditFinding] = try decodeLines("findings.jsonl", in: directory)

        try requireCanonicalOrder(nodes.map(\.id), file: "nodes.jsonl")
        try requireCanonicalOrder(edges.map(\.id), file: "edges.jsonl")
        try requireCanonicalOrder(findings.map(\.id), file: "findings.jsonl")
        let graph = SemanticGraph(
            schemaVersion: manifest.schemaVersion,
            resolution: summary.resolution,
            nodes: nodes,
            edges: edges
        )
        let report = AuditReport(
            schemaVersion: manifest.schemaVersion,
            toolVersion: manifest.toolVersion,
            resolution: summary.resolution,
            metrics: summary.metrics,
            semanticValues: summary.semanticValues,
            findings: findings
        )
        try SnapshotValidator.validate(graph: graph, report: report, manifest: manifest)
        guard nodes.count == summary.nodeCount else {
            throw SnapshotError.countMismatch("node", expected: summary.nodeCount, actual: nodes.count)
        }
        guard edges.count == summary.edgeCount else {
            throw SnapshotError.countMismatch("edge", expected: summary.edgeCount, actual: edges.count)
        }
        guard findings.count == summary.findingCount else {
            throw SnapshotError.countMismatch("finding", expected: summary.findingCount, actual: findings.count)
        }
        return SemanticSnapshot(manifest: manifest, graph: graph, report: report)
    }

    private func decodeJSON<T: Decodable>(_ file: String, in directory: URL) throws -> T {
        do {
            return try JSONDecoder().decode(T.self, from: Data(contentsOf: directory.appendingPathComponent(file)))
        } catch let error as SnapshotError {
            throw error
        } catch {
            throw SnapshotError.malformedFile(file, error.localizedDescription)
        }
    }

    private func decodeLines<T: Decodable>(_ file: String, in directory: URL) throws -> [T] {
        let data: Data
        do {
            data = try Data(contentsOf: directory.appendingPathComponent(file))
        } catch {
            throw SnapshotError.malformedFile(file, error.localizedDescription)
        }
        guard let text = String(data: data, encoding: .utf8) else {
            throw SnapshotError.malformedFile(file, "not valid UTF-8")
        }
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        let contentLines = lines.last == "" ? lines.dropLast() : lines[...]
        var values: [T] = []
        for (offset, line) in contentLines.enumerated() {
            guard !line.isEmpty else { throw SnapshotError.malformedLine(file, offset + 1, "empty line") }
            do {
                values.append(try JSONDecoder().decode(T.self, from: Data(line.utf8)))
            } catch {
                throw SnapshotError.malformedLine(file, offset + 1, error.localizedDescription)
            }
        }
        return values
    }

    private func requireCanonicalOrder(_ ids: [String], file: String) throws {
        guard ids == ids.sorted() else { throw SnapshotError.unsortedIDs(file) }
    }
}
