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

        XCTAssertEqual(graph.nodes.count, 42)
        XCTAssertEqual(graph.edges.count, 77)
        XCTAssertEqual(observedPairs, [
            "GraphExtraction.Controls.environmentModel -> GraphExtraction.Controls.environmentModel.query",
            "GraphExtraction.Controls.model -> GraphExtraction.Controls.model.mode",
            "GraphExtraction.Controls.model -> GraphExtraction.Controls.model.query",
            "GraphExtraction.Controls.model -> GraphExtraction.Controls.model.reload",
            "GraphExtraction.Controls.model -> GraphExtraction.Controls.model.volume",
        ])
    }

    func testExplicitBindingConstructionHasStableGetterSetterAndControlTopology() throws {
        let graph = try scanTemporarySource("""
        import SwiftUI
        struct CustomBindingEditor: View {
            @Binding var value: Int
            var body: some View {
                Picker("Value", selection: Binding(
                    get: { value },
                    set: { next in value = next }
                )) { Text("Zero").tag(0) }
            }
        }
        """)
        let binding = try XCTUnwrap(graph.nodes.first {
            $0.kind == .binding && $0.evidence.contains { $0.kind == "binding-construction" }
        })
        let createdClosures = graph.edges.filter { $0.kind == .creates && $0.from == binding.id }
            .compactMap { edge in graph.nodes.first { $0.id == edge.to && $0.kind == .closure } }
        let setter = try XCTUnwrap(graph.edges.first { $0.kind == .sets && $0.from == binding.id })
        let controlBinding = try XCTUnwrap(graph.edges.first { $0.kind == .binds && $0.to == binding.id })

        XCTAssertEqual(createdClosures.count, 2)
        XCTAssertTrue(createdClosures.contains { $0.id == setter.to })
        XCTAssertTrue(setter.evidence.contains { $0.kind == "binding-setter" })
        XCTAssertTrue(graph.nodes.contains { $0.id == controlBinding.from && $0.evidence.contains { $0.kind == "swiftui-control" } })
        XCTAssertTrue((binding.evidence + setter.evidence).allSatisfy {
            !$0.file.hasPrefix("/") && $0.startLine > 0 && $0.endLine >= $0.startLine
        })
        XCTAssertEqual(try graph.jsonData(), try graph.jsonData())
    }

    func testOnChangeNewValueParametersPreserveObservedIdentityOnly() throws {
        let graph = try GraphScanner().scan(path: onChangeParameterFixture.path)
        let nodes = Dictionary(uniqueKeysWithValues: graph.nodes.map { ($0.qualifiedName, $0) })
        let external = try XCTUnwrap(nodes["OnChangeParameterFixture.OnChangeParameterEditor.external"])
        let first = try XCTUnwrap(nodes["OnChangeParameterFixture.OnChangeParameterEditor.first"])
        let transformed = try XCTUnwrap(nodes["OnChangeParameterFixture.OnChangeParameterEditor.transformed"])
        let oldCopy = try XCTUnwrap(nodes["OnChangeParameterFixture.OnChangeParameterEditor.oldCopy"])
        let parameters = graph.nodes.filter {
            $0.kind == .input && $0.evidence.contains { $0.kind == "onchange-new-value" }
        }

        XCTAssertEqual(parameters.count, 2)
        for parameter in parameters {
            let alias = try XCTUnwrap(graph.edges.first {
                $0.kind == .aliases && $0.from == parameter.id &&
                    $0.evidence.contains { $0.kind == "onchange-new-value" }
            })
            XCTAssertTrue(alias.to == external.id || alias.to == first.id)
            XCTAssertTrue(graph.edges.contains { $0.kind == .owns && $0.to == parameter.id })
        }
        XCTAssertTrue(graph.edges.contains {
            $0.kind == .copiesTo && $0.from == external.id && $0.to == first.id
        })
        XCTAssertTrue(graph.edges.contains {
            $0.kind == .copiesTo && $0.from == first.id && $0.to == external.id
        })
        XCTAssertTrue(graph.edges.contains {
            $0.kind == .derivesFrom && $0.from == transformed.id && $0.to == external.id &&
                $0.evidence.contains { $0.kind == "assignment-transform" }
        })
        XCTAssertFalse(graph.edges.contains {
            $0.kind == .copiesTo && ($0.from == oldCopy.id || $0.to == oldCopy.id)
        })
        XCTAssertFalse(graph.nodes.contains { $0.name == "arbitrary" && $0.evidence.contains { $0.kind == "onchange-new-value" } })

        let source = try String(contentsOf: onChangeParameterFixture, encoding: .utf8)
        let variants = try scanTemporarySourceVariants([source, "\n\n\n" + source])
        XCTAssertEqual(variants[0].nodes.map(\.id), variants[1].nodes.map(\.id))
        XCTAssertEqual(variants[0].edges.map(\.id), variants[1].edges.map(\.id))
        XCTAssertNotEqual(variants[0].nodes.flatMap(\.evidence), variants[1].nodes.flatMap(\.evidence))
    }

    func testOnChangeParameterUseIsMonotonicAcrossLexicalCaptureAndShadowBoundaries() throws {
        let graph = try scanTemporarySource("""
        import SwiftUI
        struct OrderedParameterEditor: View {
            @Binding var external: String
            @State private var direct = ""
            @State private var captured = ""
            @State private var transformed = ""
            @State private var shadowed = ""
            @State private var deepCaptured = ""
            @State private var boundaryShadowed = ""
            func normalize(_ value: String) -> String { value.uppercased() }
            var body: some View {
                TextField("Value", text: $direct)
                    .onChange(of: external) { newValue in
                        direct = newValue
                        transformed = normalize(newValue)
                        transformed = ""
                    }
                    .onChange(of: external) { newValue in
                        withAnimation {
                            captured = newValue
                        }
                    }
                    .onChange(of: external) { newValue in
                        direct = newValue
                        let callback: (String) -> Void = { newValue in
                            shadowed = newValue
                        }
                        callback(newValue)
                    }
                    .onChange(of: external) { newValue in
                        withAnimation {
                            withAnimation {
                                deepCaptured = newValue
                            }
                            let callback: (String) -> Void = { newValue in
                                boundaryShadowed = newValue
                            }
                            callback(newValue)
                        }
                    }
                    .onChange(of: external) { newValue in
                        withAnimation {
                            transformed = normalize(newValue)
                        }
                    }
            }
        }
        """)
        let external = try XCTUnwrap(graph.nodes.first { $0.qualifiedName.hasSuffix("OrderedParameterEditor.external") })
        let direct = try XCTUnwrap(graph.nodes.first { $0.qualifiedName.hasSuffix("OrderedParameterEditor.direct") })
        let captured = try XCTUnwrap(graph.nodes.first { $0.qualifiedName.hasSuffix("OrderedParameterEditor.captured") })
        let transformed = try XCTUnwrap(graph.nodes.first { $0.qualifiedName.hasSuffix("OrderedParameterEditor.transformed") })
        let shadowed = try XCTUnwrap(graph.nodes.first { $0.qualifiedName.hasSuffix("OrderedParameterEditor.shadowed") })
        let deepCaptured = try XCTUnwrap(graph.nodes.first { $0.qualifiedName.hasSuffix("OrderedParameterEditor.deepCaptured") })
        let boundaryShadowed = try XCTUnwrap(graph.nodes.first { $0.qualifiedName.hasSuffix("OrderedParameterEditor.boundaryShadowed") })
        let aliases = graph.edges.filter {
            $0.kind == .aliases && $0.evidence.contains { $0.kind == "onchange-new-value" }
        }

        XCTAssertEqual(aliases.count, 4)
        XCTAssertTrue(aliases.allSatisfy { $0.to == external.id })
        XCTAssertTrue(graph.edges.contains { $0.kind == .copiesTo && $0.from == external.id && $0.to == direct.id })
        XCTAssertTrue(graph.edges.contains { $0.kind == .copiesTo && $0.from == external.id && $0.to == captured.id })
        XCTAssertTrue(graph.edges.contains { $0.kind == .copiesTo && $0.from == external.id && $0.to == deepCaptured.id })
        XCTAssertTrue(graph.edges.contains { $0.kind == .derivesFrom && $0.from == transformed.id && $0.to == external.id })
        XCTAssertFalse(graph.edges.contains { $0.kind == .copiesTo && $0.from == external.id && $0.to == shadowed.id })
        XCTAssertFalse(graph.edges.contains { $0.kind == .copiesTo && $0.from == external.id && $0.to == boundaryShadowed.id })
    }

    func testConditionalAndLexicalScopesHaveDistinctStableTopology() throws {
        let source = try String(contentsOf: identityScopeFixture, encoding: .utf8)
        let variants = try scanTemporarySourceVariants([source, source, "\n\n\n" + source])
        let graph = variants[0]
        let repeated = variants[1]
        let shifted = variants[2]

        XCTAssertEqual(try graph.jsonData(), try repeated.jsonData())
        XCTAssertEqual(graph.nodes.map(\.id), shifted.nodes.map(\.id))
        XCTAssertEqual(graph.edges.map(\.id), shifted.edges.map(\.id))
        XCTAssertNotEqual(graph.nodes.flatMap(\.evidence), shifted.nodes.flatMap(\.evidence))
        let nodeIDs = Set(graph.nodes.map(\.id))
        XCTAssertTrue(graph.edges.allSatisfy { nodeIDs.contains($0.from) && nodeIDs.contains($0.to) })

        let conditionalTypes = graph.nodes.filter { $0.kind == .type && $0.name == "ConditionalService" }
        let conditionalFunctions = graph.nodes.filter { $0.kind == .function && $0.name == "resolve" }
        let conditionalResults = graph.nodes.filter { $0.kind == .property && $0.name == "result" }
        XCTAssertEqual(conditionalTypes.count, 2)
        XCTAssertEqual(Set(conditionalTypes.map(\.id)).count, 2)
        XCTAssertTrue(conditionalTypes.allSatisfy { $0.qualifiedName.contains("[ifconfig:") })
        XCTAssertEqual(conditionalFunctions.count, 2)
        XCTAssertEqual(conditionalResults.count, 2)
        for type in conditionalTypes {
            let functions = graph.edges.filter { $0.kind == .owns && $0.from == type.id }
                .compactMap { edge in graph.nodes.first { $0.id == edge.to && $0.name == "resolve" } }
            XCTAssertEqual(functions.count, 1)
            let function = try XCTUnwrap(functions.first)
            let ownedResults = graph.edges.filter { $0.kind == .owns && $0.from == function.id }
                .compactMap { edge in graph.nodes.first { $0.id == edge.to && $0.name == "result" } }
            XCTAssertEqual(ownedResults.count, 1)
            XCTAssertTrue(graph.edges.contains {
                $0.kind == .reads && $0.from == function.id && $0.to == ownedResults[0].id
            })
            XCTAssertFalse(graph.edges.contains { edge in
                edge.kind == .reads && edge.from == function.id &&
                    conditionalResults.contains { result in
                        result.id == edge.to && result.id != ownedResults[0].id
                    }
            })
        }

        let repeatedBlockValues = graph.nodes.filter {
            $0.kind == .property && $0.name == "value" && $0.qualifiedName.contains("repeatedBlocks")
        }
        XCTAssertEqual(repeatedBlockValues.count, 2)
        XCTAssertEqual(Set(repeatedBlockValues.map(\.id)).count, 2)
        XCTAssertTrue(repeatedBlockValues.allSatisfy { $0.qualifiedName.contains("[block:") })

        let closureValues = graph.nodes.filter {
            $0.kind == .property && $0.name == "value" && $0.qualifiedName.contains("closureScopes")
        }
        XCTAssertEqual(closureValues.count, 2)
        XCTAssertEqual(Set(closureValues.map(\.id)).count, 2)
        XCTAssertTrue(closureValues.allSatisfy { $0.qualifiedName.contains("[closure:") })
        for value in closureValues {
            XCTAssertEqual(
                graph.edges.filter { edge in
                    edge.kind == .reads && edge.to == value.id &&
                        graph.nodes.contains { node in node.id == edge.from && node.kind == .closure }
                }.count,
                1
            )
        }

        let scopeHost = try XCTUnwrap(graph.nodes.first { $0.kind == .type && $0.name == "ScopeHost" })
        XCTAssertTrue(scopeHost.evidence.contains { $0.kind == "type-declaration" })
        XCTAssertTrue(scopeHost.evidence.contains { $0.kind == "extension-declaration" })
        let extended = try XCTUnwrap(graph.nodes.first { $0.kind == .function && $0.name == "extended" })
        XCTAssertTrue(graph.edges.contains { $0.kind == .owns && $0.from == scopeHost.id && $0.to == extended.id })
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

    private func scanTemporarySourceVariants(_ sources: [String]) throws -> [SemanticGraph] {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("swiftui-audit-extraction-variants-(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let file = root.appendingPathComponent("Fixture.swift")
        return try sources.map { source in
            try source.write(to: file, atomically: true, encoding: .utf8)
            return try GraphScanner().scan(path: root.path)
        }
    }

    private var identityScopeFixture: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .appendingPathComponent("Fixtures/IdentityScopesFixture.swift")
    }

    private var onChangeParameterFixture: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .appendingPathComponent("Fixtures/OnChangeParameterFixture.swift")
    }
}
