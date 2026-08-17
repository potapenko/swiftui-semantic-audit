import AuditCore
import AuditRules
import Foundation
import SnapshotStore
import SwiftSyntaxFrontend
import XCTest

final class SnapshotStoreTests: XCTestCase {
    func testSnapshotIsByteStableExactlyFiveFilesAndRoundTrips() throws {
        let graph = try GraphScanner().scan(path: fixtureRoot.path)
        let report = AuditEngine().audit(graph: graph)
        let manifest = SnapshotManifestFactory.make(sourcePath: fixtureRoot.path, toolVersion: report.toolVersion)
        let temporary = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporary) }
        let first = temporary.appendingPathComponent("first")
        let second = temporary.appendingPathComponent("second")

        try SnapshotWriter().write(
            graph: graph, report: report, manifest: manifest, sourceURL: fixtureRoot, to: first
        )
        try SnapshotWriter().write(
            graph: graph, report: report, manifest: manifest, sourceURL: fixtureRoot, to: second
        )

        let files = try FileManager.default.contentsOfDirectory(atPath: first.path).sorted()
        XCTAssertEqual(files, SnapshotWriter.requiredFiles.sorted())
        for file in SnapshotWriter.requiredFiles {
            let firstData = try Data(contentsOf: first.appendingPathComponent(file))
            let secondData = try Data(contentsOf: second.appendingPathComponent(file))
            XCTAssertEqual(firstData, secondData, "non-deterministic \(file)")
            let text = String(decoding: firstData, as: UTF8.self)
            XCTAssertFalse(text.contains(projectRoot.path))
            XCTAssertFalse(text.contains(temporary.path))
        }

        let snapshot = try SnapshotReader().read(from: first)
        XCTAssertEqual(snapshot.manifest, manifest)
        XCTAssertEqual(snapshot.graph, graph)
        XCTAssertEqual(snapshot.report, report)
        try assertJSONLinesAreValidAndSorted(first.appendingPathComponent("nodes.jsonl"), id: SemanticNode.self)
        try assertJSONLinesAreValidAndSorted(first.appendingPathComponent("edges.jsonl"), id: SemanticEdge.self)
        try assertJSONLinesAreValidAndSorted(first.appendingPathComponent("findings.jsonl"), id: AuditFinding.self)
    }

    func testWriterReplacesExistingSnapshotWithoutLeavingRecoveryDirectories() throws {
        let graph = try GraphScanner().scan(path: fixtureRoot.path)
        let report = AuditEngine().audit(graph: graph)
        let manifest = SnapshotManifestFactory.make(sourcePath: fixtureRoot.path)
        let temporary = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporary) }
        let output = temporary.appendingPathComponent("semantic")

        try SnapshotWriter().write(
            graph: graph, report: report, manifest: manifest, sourceURL: fixtureRoot, to: output
        )
        try SnapshotWriter().write(
            graph: graph, report: report, manifest: manifest, sourceURL: fixtureRoot, to: output
        )

        XCTAssertNoThrow(try SnapshotReader().read(from: output))
        let siblings = try FileManager.default.contentsOfDirectory(atPath: temporary.path)
        XCTAssertEqual(siblings, ["semantic"])
    }

    func testWriterRejectsSourceAndAncestorOutputAfterCanonicalSymlinkResolution() throws {
        let (graph, report, manifest) = try fixtureAudit()
        let temporary = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporary) }
        let project = temporary.appendingPathComponent("Project", isDirectory: true)
        try FileManager.default.createDirectory(at: project, withIntermediateDirectories: true)
        let sentinel = project.appendingPathComponent("sentinel.txt")
        let sentinelBytes = Data("source-must-survive".utf8)
        try sentinelBytes.write(to: sentinel)
        let projectLink = temporary.appendingPathComponent("ProjectLink")
        try FileManager.default.createSymbolicLink(at: projectLink, withDestinationURL: project)

        let attempts: [(source: URL, output: URL)] = [
            (project, project),
            (project, project.appendingPathComponent("nested/..")),
            (project, temporary),
            (projectLink, project),
            (project, projectLink),
        ]
        for attempt in attempts {
            XCTAssertThrowsError(try SnapshotWriter().write(
                graph: graph,
                report: report,
                manifest: manifest,
                sourceURL: attempt.source,
                to: attempt.output
            )) {
                guard case SnapshotError.sourceOutputOverlap = $0 else {
                    return XCTFail("unexpected error: \($0)")
                }
            }
            XCTAssertEqual(try Data(contentsOf: sentinel), sentinelBytes)
        }
    }

    func testWriterInitializesEmptyOutputButRefusesNonSnapshotWithoutChangingSentinel() throws {
        let (graph, report, manifest) = try fixtureAudit()
        let temporary = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporary) }
        let empty = temporary.appendingPathComponent("empty")
        try FileManager.default.createDirectory(at: empty, withIntermediateDirectories: true)

        try SnapshotWriter().write(
            graph: graph, report: report, manifest: manifest, sourceURL: fixtureRoot, to: empty
        )
        XCTAssertEqual(
            try FileManager.default.contentsOfDirectory(atPath: empty.path).sorted(),
            SnapshotWriter.requiredFiles.sorted()
        )

        let nonSnapshot = temporary.appendingPathComponent("operator-data")
        try FileManager.default.createDirectory(at: nonSnapshot, withIntermediateDirectories: true)
        let sentinel = nonSnapshot.appendingPathComponent("keep.txt")
        let bytes = Data("do-not-touch".utf8)
        try bytes.write(to: sentinel)
        XCTAssertThrowsError(try SnapshotWriter().write(
            graph: graph,
            report: report,
            manifest: manifest,
            sourceURL: fixtureRoot,
            to: nonSnapshot
        )) {
            guard case SnapshotError.existingOutputNotSnapshot = $0 else {
                return XCTFail("unexpected error: \($0)")
            }
        }
        XCTAssertEqual(try Data(contentsOf: sentinel), bytes)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: nonSnapshot.path), ["keep.txt"])
    }

    func testPriorValidSnapshotSurvivesValidationFailureAndRogueEntryIsStrictlyRejected() throws {
        let (graph, report, manifest) = try fixtureAudit()
        let temporary = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporary) }
        let output = temporary.appendingPathComponent("semantic")
        try SnapshotWriter().write(
            graph: graph, report: report, manifest: manifest, sourceURL: fixtureRoot, to: output
        )
        let original = try snapshotBytes(at: output)
        let badEdge = SemanticEdge(
            id: "edge:invalid",
            kind: .reads,
            from: graph.nodes[0].id,
            to: "node:missing",
            evidence: graph.nodes[0].evidence,
            confidence: .deterministic
        )
        let invalidGraph = SemanticGraph(nodes: graph.nodes, edges: graph.edges + [badEdge])

        XCTAssertThrowsError(try SnapshotWriter().write(
            graph: invalidGraph,
            report: report,
            manifest: manifest,
            sourceURL: fixtureRoot,
            to: output
        ))
        XCTAssertEqual(try snapshotBytes(at: output), original)

        let rogue = output.appendingPathComponent("rogue.txt")
        let rogueBytes = Data("operator-sentinel".utf8)
        try rogueBytes.write(to: rogue)
        XCTAssertThrowsError(try SnapshotReader().read(from: output)) {
            XCTAssertEqual($0 as? SnapshotError, .unexpectedEntries(["rogue.txt"]))
        }
        XCTAssertThrowsError(try SnapshotWriter().write(
            graph: graph,
            report: report,
            manifest: manifest,
            sourceURL: fixtureRoot,
            to: output
        )) {
            guard case SnapshotError.existingOutputNotSnapshot = $0 else {
                return XCTFail("unexpected error: \($0)")
            }
        }
        XCTAssertEqual(try Data(contentsOf: rogue), rogueBytes)
        for (file, bytes) in original {
            XCTAssertEqual(try Data(contentsOf: output.appendingPathComponent(file)), bytes)
        }
    }

    func testReaderRejectsMalformedDuplicateDanglingAndSchemaMismatch() throws {
        let graph = try GraphScanner().scan(path: fixtureRoot.path)
        let report = AuditEngine().audit(graph: graph)
        let manifest = SnapshotManifestFactory.make(sourcePath: fixtureRoot.path)
        let temporary = makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: temporary) }

        let malformed = temporary.appendingPathComponent("malformed")
        try SnapshotWriter().write(
            graph: graph, report: report, manifest: manifest, sourceURL: fixtureRoot, to: malformed
        )
        try Data("{\n".utf8).write(to: malformed.appendingPathComponent("nodes.jsonl"))
        XCTAssertThrowsError(try SnapshotReader().read(from: malformed)) {
            guard case SnapshotError.malformedLine("nodes.jsonl", 1, _) = $0 else {
                return XCTFail("unexpected error: \($0)")
            }
        }

        let duplicate = temporary.appendingPathComponent("duplicate")
        try SnapshotWriter().write(
            graph: graph, report: report, manifest: manifest, sourceURL: fixtureRoot, to: duplicate
        )
        let nodesURL = duplicate.appendingPathComponent("nodes.jsonl")
        let nodesData = try Data(contentsOf: nodesURL)
        let firstLine = try XCTUnwrap(String(decoding: nodesData, as: UTF8.self).split(separator: "\n").first)
        var duplicateData = Data(firstLine.utf8)
        duplicateData.append(0x0A)
        duplicateData.append(nodesData)
        try duplicateData.write(to: nodesURL)
        XCTAssertThrowsError(try SnapshotReader().read(from: duplicate)) {
            guard case SnapshotError.duplicateID("nodes.jsonl", _) = $0 else {
                return XCTFail("unexpected error: \($0)")
            }
        }

        let dangling = temporary.appendingPathComponent("dangling")
        try SnapshotWriter().write(
            graph: graph, report: report, manifest: manifest, sourceURL: fixtureRoot, to: dangling
        )
        let edgeURL = dangling.appendingPathComponent("edges.jsonl")
        var edgeLines = String(decoding: try Data(contentsOf: edgeURL), as: UTF8.self)
            .split(separator: "\n").map(String.init)
        let firstEdge = try JSONDecoder().decode(SemanticEdge.self, from: Data(edgeLines[0].utf8))
        let broken = SemanticEdge(
            id: firstEdge.id,
            kind: firstEdge.kind,
            from: firstEdge.from,
            to: "node:missing",
            evidence: firstEdge.evidence,
            confidence: firstEdge.confidence
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        edgeLines[0] = String(decoding: try encoder.encode(broken), as: UTF8.self)
        try Data((edgeLines.joined(separator: "\n") + "\n").utf8).write(to: edgeURL)
        XCTAssertThrowsError(try SnapshotReader().read(from: dangling)) {
            guard case SnapshotError.danglingEdge(_, "node:missing") = $0 else {
                return XCTFail("unexpected error: \($0)")
            }
        }

        let schema = temporary.appendingPathComponent("schema")
        try SnapshotWriter().write(
            graph: graph, report: report, manifest: manifest, sourceURL: fixtureRoot, to: schema
        )
        let future = SnapshotManifest(
            schemaVersion: 99,
            toolVersion: manifest.toolVersion,
            swiftVersion: manifest.swiftVersion,
            repositoryRevision: manifest.repositoryRevision,
            generatedFrom: manifest.generatedFrom
        )
        try encoder.encode(future).write(to: schema.appendingPathComponent("manifest.json"))
        XCTAssertThrowsError(try SnapshotReader().read(from: schema)) {
            XCTAssertEqual($0 as? SnapshotError, .unsupportedSchema(99))
        }
    }

    private var projectRoot: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    }

    private var fixtureRoot: URL {
        projectRoot.appendingPathComponent("Tests/Fixtures/RuleTests", isDirectory: true)
    }

    private func makeTemporaryDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("swiftui-audit-snapshot-tests-\(UUID().uuidString)")
        try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func fixtureAudit() throws -> (SemanticGraph, AuditReport, SnapshotManifest) {
        let graph = try GraphScanner().scan(path: fixtureRoot.path)
        let report = AuditEngine().audit(graph: graph)
        return (graph, report, SnapshotManifestFactory.make(sourcePath: fixtureRoot.path))
    }

    private func snapshotBytes(at directory: URL) throws -> [String: Data] {
        try Dictionary(uniqueKeysWithValues: SnapshotWriter.requiredFiles.map { file in
            (file, try Data(contentsOf: directory.appendingPathComponent(file)))
        })
    }

    private func assertJSONLinesAreValidAndSorted<T: Decodable>(
        _ url: URL,
        id type: T.Type
    ) throws {
        let lines = String(decoding: try Data(contentsOf: url), as: UTF8.self).split(separator: "\n")
        XCTAssertFalse(lines.isEmpty)
        for line in lines {
            XCTAssertNoThrow(try JSONDecoder().decode(T.self, from: Data(line.utf8)))
        }
        let identifiers: [String]
        if T.self == SemanticNode.self {
            identifiers = try lines.map { try JSONDecoder().decode(SemanticNode.self, from: Data($0.utf8)).id }
        } else if T.self == SemanticEdge.self {
            identifiers = try lines.map { try JSONDecoder().decode(SemanticEdge.self, from: Data($0.utf8)).id }
        } else {
            identifiers = try lines.map { try JSONDecoder().decode(AuditFinding.self, from: Data($0.utf8)).id }
        }
        XCTAssertEqual(identifiers, identifiers.sorted())
    }
}
