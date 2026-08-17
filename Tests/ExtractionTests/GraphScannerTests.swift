import AuditCore
import Foundation
import SwiftSyntaxFrontend
import XCTest

final class GraphScannerTests: XCTestCase {
    private var fixturePath: String {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures/GraphExtraction")
            .path
    }

    func testFixtureExtractsRequiredSwiftUIFacts() throws {
        let graph = try GraphScanner().scan(path: fixturePath)

        try assertEdge(.owns, from: "GraphExtraction.Controls", to: "GraphExtraction.Controls.query", in: graph)
        try assertEdge(.binds, from: "GraphExtraction.Controls", to: "GraphExtraction.Controls.isEnabled", in: graph)
        try assertEdge(.owns, from: "GraphExtraction.Controls", to: "GraphExtraction.Controls.onCommit", in: graph)
        try assertEdge(.observes, from: "GraphExtraction.Controls", to: "GraphExtraction.Controls.model", in: graph)
        try assertEdge(.injects, from: "GraphExtraction.Controls", to: "GraphExtraction.Controls.environmentModel", in: graph)

        try assertEdge(.creates, from: "GraphExtraction.Controls", to: "GraphExtraction.Controls.VStack#1", in: graph)
        try assertEdge(.creates, from: "GraphExtraction.Controls.VStack#1", to: "GraphExtraction.Controls.VStack#1.closure#1", in: graph)
        let containerClosure = "GraphExtraction.Controls.VStack#1.closure#1"
        for control in ["TextField", "Toggle", "Slider", "Picker"] {
            try assertEdge(.creates, from: containerClosure, to: "\(containerClosure).\(control)#1", in: graph)
        }
        try assertEdge(
            .creates,
            from: "\(containerClosure).Picker#1",
            to: "\(containerClosure).Picker#1.closure#1",
            in: graph
        )

        for modifier in ["onChange", "onAppear", "task"] {
            let modifierName = "GraphExtraction.Controls.\(modifier)#1"
            try assertEdge(.creates, from: "GraphExtraction.Controls", to: modifierName, in: graph)
            try assertEdge(.creates, from: modifierName, to: "\(modifierName).closure#1", in: graph)
        }

        try assertEdge(
            .binds,
            from: "\(containerClosure).TextField#1",
            to: "\(containerClosure).TextField#1.$query",
            in: graph
        )
        try assertEdge(
            .aliases,
            from: "\(containerClosure).TextField#1.$query",
            to: "GraphExtraction.Controls.query",
            in: graph
        )
        try assertEdge(
            .triggers,
            from: "GraphExtraction.Controls.query",
            to: "GraphExtraction.Controls.onChange#1",
            in: graph
        )
        try assertEdge(
            .writes,
            from: "GraphExtraction.Controls.onAppear#1.closure#1",
            to: "GraphExtraction.Controls.environmentModel.query",
            in: graph
        )
        try assertEdge(
            .copiesTo,
            from: "GraphExtraction.Controls.query",
            to: "GraphExtraction.Controls.environmentModel.query",
            in: graph
        )
        try assertEdge(
            .calls,
            from: "GraphExtraction.Controls.onChange#1.closure#1",
            to: "GraphExtraction.Controls.onCommit",
            in: graph
        )
        try assertEdge(
            .passes,
            from: "GraphExtraction.Parent.enabled",
            to: "GraphExtraction.Controls.isEnabled",
            in: graph
        )
        try assertEdge(
            .passes,
            from: "GraphExtraction.Parent.closure#1",
            to: "GraphExtraction.Controls.onCommit",
            in: graph
        )
    }

    func testOverloadsHaveDistinctStableIDsAndAmbiguousCallIsNotMisresolved() throws {
        let graph = try scanTemporarySource("""
        struct Worker {
            func update(value: Int) {}
            func update(value: String) {}
            func run() { update(value: 1) }
        }
        """)
        let overloads = graph.nodes.filter { $0.kind == .function && $0.name == "update" }
        let overloadIDs = Set(overloads.map(\.id))

        XCTAssertEqual(overloads.count, 2)
        XCTAssertEqual(overloadIDs.count, 2)
        XCTAssertFalse(graph.edges.contains { $0.kind == .calls && overloadIDs.contains($0.to) })
    }

    func testDuplicateDeclarationIdentityFailsInsteadOfMerging() throws {
        XCTAssertThrowsError(try scanTemporarySource("""
        struct Duplicate {}
        struct Duplicate {}
        """)) { error in
            guard case GraphScannerError.stableIdentityCollision(let identities) = error else {
                return XCTFail("unexpected error: \(error)")
            }
            XCTAssertEqual(identities.count, 1)
            XCTAssertTrue(identities[0].contains("Duplicate"))
        }
    }

    func testEvidenceIsRelativeAndLineLevel() throws {
        let graph = try GraphScanner().scan(path: fixturePath)
        let allEvidence = graph.nodes.flatMap(\.evidence) + graph.edges.flatMap(\.evidence)

        XCTAssertFalse(allEvidence.isEmpty)
        XCTAssertTrue(allEvidence.allSatisfy { !$0.file.hasPrefix("/") })
        XCTAssertTrue(allEvidence.contains { $0.file == "Fixture.swift" && $0.startLine > 1 })
        XCTAssertTrue(allEvidence.allSatisfy { $0.startLine >= 1 && $0.endLine >= $0.startLine })
    }

    func testStableIDsDoNotDependOnLeadingLines() throws {
        let temporaryRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("swiftui-audit-stable-id-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: temporaryRoot, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporaryRoot) }

        let file = temporaryRoot.appendingPathComponent("Sample.swift")
        let source = """
        import SwiftUI
        struct Sample: View {
            @State var value = false
            var body: some View { Toggle("Value", isOn: $value) }
            func update(value: Int) {}
            func update(value: String) {}
        }
        """
        try source.write(to: file, atomically: true, encoding: .utf8)
        let before = try GraphScanner().scan(path: temporaryRoot.path)
        try ("\n\n\n" + source).write(to: file, atomically: true, encoding: .utf8)
        let after = try GraphScanner().scan(path: temporaryRoot.path)

        XCTAssertEqual(before.nodes.map(\.id), after.nodes.map(\.id))
        XCTAssertEqual(before.edges.map(\.id), after.edges.map(\.id))
        XCTAssertNotEqual(before.nodes.flatMap(\.evidence), after.nodes.flatMap(\.evidence))
    }

    func testJSONEncodingIsByteStableAndReferencesExistingNodes() throws {
        let graph = try GraphScanner().scan(path: fixturePath)
        let first = try graph.jsonData()
        let second = try graph.jsonData()
        let ids = Set(graph.nodes.map(\.id))

        XCTAssertEqual(first, second)
        XCTAssertEqual(graph.schemaVersion, 1)
        XCTAssertEqual(graph.resolution, "syntax-only")
        XCTAssertTrue(graph.edges.allSatisfy { ids.contains($0.from) && ids.contains($0.to) })
        XCTAssertNoThrow(try JSONSerialization.jsonObject(with: first))
    }

    func testP2ObservableEnrichmentIsExactlyFiveAdditiveEdges() throws {
        let graph = try GraphScanner().scan(path: fixturePath)
        let nodesByID = Dictionary(uniqueKeysWithValues: graph.nodes.map { ($0.id, $0.qualifiedName) })
        let observedPairs = graph.edges.filter {
            $0.kind == .observes && $0.evidence.contains { $0.kind == "observable-member" }
        }.map { "\(nodesByID[$0.from]!) -> \(nodesByID[$0.to]!)" }.sorted()

        XCTAssertEqual(graph.nodes.count, 41)
        XCTAssertEqual(graph.edges.count, 72)
        XCTAssertEqual(observedPairs, [
            "GraphExtraction.Controls.environmentModel -> GraphExtraction.Controls.environmentModel.query",
            "GraphExtraction.Controls.model -> GraphExtraction.Controls.model.mode",
            "GraphExtraction.Controls.model -> GraphExtraction.Controls.model.query",
            "GraphExtraction.Controls.model -> GraphExtraction.Controls.model.reload",
            "GraphExtraction.Controls.model -> GraphExtraction.Controls.model.volume",
        ])
    }

    private func assertEdge(
        _ kind: EdgeKind,
        from fromQualifiedName: String,
        to toQualifiedName: String,
        in graph: SemanticGraph,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let from = try XCTUnwrap(
            graph.nodes.first { $0.qualifiedName == fromQualifiedName },
            "missing node \(fromQualifiedName)",
            file: file,
            line: line
        )
        let to = try XCTUnwrap(
            graph.nodes.first { $0.qualifiedName == toQualifiedName },
            "missing node \(toQualifiedName)",
            file: file,
            line: line
        )
        XCTAssertTrue(
            graph.edges.contains { $0.kind == kind && $0.from == from.id && $0.to == to.id },
            "missing \(kind.rawValue) edge \(fromQualifiedName) -> \(toQualifiedName)",
            file: file,
            line: line
        )
        if kind == .creates {
            XCTAssertEqual(
                Set(graph.edges.filter { $0.kind == .creates && $0.to == to.id }.map(\.from)),
                [from.id],
                "unexpected creator for \(toQualifiedName)",
                file: file,
                line: line
            )
        }
    }

    private func scanTemporarySource(_ source: String) throws -> SemanticGraph {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("swiftui-audit-extraction-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try source.write(to: root.appendingPathComponent("Fixture.swift"), atomically: true, encoding: .utf8)
        return try GraphScanner().scan(path: root.path)
    }
}
