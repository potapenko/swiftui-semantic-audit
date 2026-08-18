import AuditCore
import AuditRules
import Foundation
import SwiftSyntaxFrontend
import XCTest

final class RuleAcceptanceTests: XCTestCase {
    private let expectations: [(fixture: String, rules: Set<RuleID>)] = [
        ("GoodDirectBinding", []),
        ("ValueSetterPair", [.valueSetterPair]),
        ("BidirectionalOnChange", [.mirroredState, .manualTwoWaySync]),
        ("TransactionalDraft", []),
        ("DerivedState", [.storedDerivedState]),
        ("CallbackTunnel", [.callbackBindingTunnel]),
        ("ObservableMirror", [.observableStateMirror]),
        ("IntentionalTransformation", []),
        ("BindingMirroredLocally", [.mirroredState, .manualTwoWaySync]),
        ("BindingTransactionalDraft", []),
        ("BindingIndependentLocalState", []),
        ("BindingSelfCopy", []),
        ("CommandBinding", [.commandShapedBinding, .broadObservableInput]),
        ("BindingWithEffect", [.commandShapedBinding]),
        ("BindingFactory", [.bindingFactory]),
        ("ObservableModelTunnel", [.observableModelTunnel]),
        ("BroadObservableInput", [.broadObservableInput]),
        ("DirectCustomBinding", []),
        ("TransformedBinding", []),
        ("FocusedBindingChain", []),
        ("LocalModelOwner", []),
        ("FocusedActionInput", []),
    ]

    func testAcceptanceFixturesHaveExactMandatoryFindings() throws {
        for expectation in expectations {
            let report = try auditFixture(expectation.fixture)
            XCTAssertEqual(
                Set(report.findings.map(\.rule)),
                expectation.rules,
                "unexpected findings for \(expectation.fixture)"
            )
        }
    }

    func testTransactionalDraftIsClassifiedWithoutBindingFinding() throws {
        let report = try auditFixture("TransactionalDraft")
        let transactionalValues = report.semanticValues.filter { $0.classification == .transactionalDraft }

        XCTAssertEqual(transactionalValues.count, 1)
        XCTAssertTrue(report.findings.isEmpty)
        XCTAssertGreaterThanOrEqual(transactionalValues[0].representations.count, 2)
    }

    func testBindingMirroredIntoLocalStateProducesBothTopologyFindings() throws {
        let graph = try graphFixture("BindingMirroredLocally")
        let report = AuditEngine().audit(graph: graph)

        XCTAssertEqual(Set(report.findings.map(\.rule)), [.mirroredState, .manualTwoWaySync])
        XCTAssertEqual(report.findings.count, 2)
        for finding in report.findings {
            XCTAssertEqual(Set(finding.nodes.compactMap { id in graph.nodes.first { $0.id == id }?.kind }), [.binding, .state])
            XCTAssertEqual(finding.edges.compactMap { id in graph.edges.first { $0.id == id }?.kind }, [.copiesTo, .copiesTo])
            XCTAssertTrue(finding.evidence.allSatisfy { !$0.file.hasPrefix("/") && $0.startLine > 0 })
        }
        XCTAssertEqual(report.metrics.manualSynchronizationEdges, 2)
        XCTAssertEqual(report.metrics.duplicatedSourcesOfTruth, 1)
        XCTAssertEqual(report.metrics.ownershipViolations, 1)
    }

    func testBindingWithoutIdentityMirrorRemainsClean() throws {
        for fixture in ["GoodDirectBinding", "BindingIndependentLocalState"] {
            let report = try auditFixture(fixture)
            XCTAssertTrue(report.findings.isEmpty, "\(fixture) must remain clean")
            XCTAssertEqual(report.metrics.manualSynchronizationEdges, 0)
            XCTAssertEqual(report.metrics.duplicatedSourcesOfTruth, 0)
            XCTAssertEqual(report.metrics.ownershipViolations, 0)
        }
    }

    func testBindingSelfCopyIsNotAReciprocalPair() throws {
        let graph = try graphFixture("BindingSelfCopy")
        let selfCopies = graph.edges.filter {
            $0.kind == .copiesTo && $0.from == $0.to &&
                $0.evidence.contains { $0.kind == "assignment" }
        }
        let report = AuditEngine().audit(graph: graph)

        XCTAssertEqual(selfCopies.count, 1)
        XCTAssertTrue(report.findings.isEmpty)
        XCTAssertEqual(report.metrics.manualSynchronizationEdges, 0)
        XCTAssertEqual(report.metrics.duplicatedSourcesOfTruth, 0)
        XCTAssertEqual(report.metrics.ownershipViolations, 0)
        XCTAssertGreaterThan(report.metrics.bindingEdges, 0)
    }

    func testOnChangeNewValueParametersProduceBindingMirrorFindings() throws {
        let variants = [
            (
                "{ newValue in editableName = newValue }",
                "{ newValue in profileName = newValue }"
            ),
            (
                "{ _, newValue in editableName = newValue }",
                "{ _, newValue in profileName = newValue }"
            ),
        ]
        for (forward, reverse) in variants {
            let report = try auditTemporarySource("""
            import SwiftUI
            struct ParameterMirror: View {
                @Binding var profileName: String
                @State private var editableName = ""
                var body: some View {
                    TextField("Name", text: $editableName)
                        .onChange(of: profileName) \(forward)
                        .onChange(of: editableName) \(reverse)
                }
            }
            """, moduleName: "ParameterMirror")

            XCTAssertEqual(Set(report.findings.map(\.rule)), [.mirroredState, .manualTwoWaySync])
            XCTAssertEqual(report.metrics.manualSynchronizationEdges, 2)
            XCTAssertEqual(report.metrics.duplicatedSourcesOfTruth, 1)
            XCTAssertEqual(report.metrics.ownershipViolations, 1)
        }
    }

    func testOnChangeNewValueTransformDoesNotCreateIdentityCycle() throws {
        let report = try auditTemporarySource("""
        import SwiftUI
        struct ParameterTransform: View {
            @Binding var profileName: String
            @State private var editableName = ""
            func normalize(_ value: String) -> String { value.uppercased() }
            func denormalize(_ value: String) -> String { value.lowercased() }
            var body: some View {
                TextField("Name", text: $editableName)
                    .onChange(of: profileName) { newValue in
                        editableName = normalize(newValue)
                    }
                    .onChange(of: editableName) { _, newValue in
                        profileName = denormalize(newValue)
                    }
            }
        }
        """, moduleName: "ParameterTransform")

        XCTAssertTrue(report.findings.isEmpty)
        XCTAssertEqual(report.metrics.manualSynchronizationEdges, 0)
        XCTAssertEqual(report.metrics.duplicatedSourcesOfTruth, 0)
        XCTAssertEqual(report.metrics.ownershipViolations, 0)
        XCTAssertFalse(report.findings.flatMap(\.suggestedPatterns).contains("Binding"))
    }

    func testOnChangeParameterIdentityIsOrderIndependentAndLexicallyScoped() throws {
        let ordered = try auditTemporarySource("""
        import SwiftUI
        struct OrderedMirror: View {
            @Binding var profileName: String
            @State private var editableName = ""
            private var scratch = ""
            func normalize(_ value: String) -> String { value.uppercased() }
            var body: some View {
                TextField("Name", text: $editableName)
                    .onChange(of: profileName) { newValue in
                        editableName = newValue
                        scratch = normalize(newValue)
                        scratch = ""
                    }
                    .onChange(of: editableName) { _, newValue in
                        scratch = ""
                        profileName = newValue
                        scratch = normalize(newValue)
                    }
            }
        }
        """, moduleName: "OrderedMirror")

        XCTAssertEqual(Set(ordered.findings.map(\.rule)), [.mirroredState, .manualTwoWaySync])
        XCTAssertEqual(ordered.metrics.manualSynchronizationEdges, 2)
        XCTAssertEqual(ordered.metrics.duplicatedSourcesOfTruth, 1)
        XCTAssertEqual(ordered.metrics.ownershipViolations, 1)

        let captured = try auditTemporarySource("""
        import SwiftUI
        struct CapturedMirror: View {
            @Binding var profileName: String
            @State private var editableName = ""
            @State private var shadowTarget = ""
            var body: some View {
                TextField("Name", text: $editableName)
                    .onChange(of: profileName) { newValue in
                        withAnimation {
                            editableName = newValue
                        }
                    }
                    .onChange(of: editableName) { _, newValue in
                        profileName = newValue
                        let callback: (String) -> Void = { newValue in
                            shadowTarget = newValue
                        }
                        callback(newValue)
                    }
            }
        }
        """, moduleName: "CapturedMirror")

        XCTAssertEqual(Set(captured.findings.map(\.rule)), [.mirroredState, .manualTwoWaySync])
        XCTAssertEqual(captured.metrics.manualSynchronizationEdges, 2)
        XCTAssertEqual(captured.metrics.duplicatedSourcesOfTruth, 1)
        XCTAssertEqual(captured.metrics.ownershipViolations, 1)

        let nestedOnly = try auditTemporarySource("""
        import SwiftUI
        struct NestedOnlyMirror: View {
            @Binding var profileName: String
            @State private var editableName = ""
            var body: some View {
                TextField("Name", text: $editableName)
                    .onChange(of: profileName) { newValue in
                        let callback: (String) -> Void = { newValue in
                            editableName = newValue
                        }
                        callback(newValue)
                    }
                    .onChange(of: editableName) { newValue in
                        let callback: (String) -> Void = { newValue in
                            profileName = newValue
                        }
                        callback(newValue)
                    }
            }
        }
        """, moduleName: "NestedOnlyMirror")

        XCTAssertTrue(nestedOnly.findings.isEmpty)
        XCTAssertEqual(nestedOnly.metrics.manualSynchronizationEdges, 0)
        XCTAssertEqual(nestedOnly.metrics.duplicatedSourcesOfTruth, 0)
        XCTAssertEqual(nestedOnly.metrics.ownershipViolations, 0)

        let transformedCapture = try auditTemporarySource("""
        import SwiftUI
        struct TransformedCapture: View {
            @Binding var profileName: String
            @State private var editableName = ""
            func normalize(_ value: String) -> String { value.uppercased() }
            func denormalize(_ value: String) -> String { value.lowercased() }
            var body: some View {
                TextField("Name", text: $editableName)
                    .onChange(of: profileName) { newValue in
                        withAnimation {
                            editableName = normalize(newValue)
                        }
                    }
                    .onChange(of: editableName) { _, newValue in
                        withAnimation {
                            profileName = denormalize(newValue)
                        }
                    }
            }
        }
        """, moduleName: "TransformedCapture")

        XCTAssertTrue(transformedCapture.findings.isEmpty)
        XCTAssertEqual(transformedCapture.metrics.manualSynchronizationEdges, 0)
        XCTAssertEqual(transformedCapture.metrics.duplicatedSourcesOfTruth, 0)
        XCTAssertEqual(transformedCapture.metrics.ownershipViolations, 0)
    }

    func testBindingBackedTransactionalDraftRemainsSuppressed() throws {
        let graph = try graphFixture("BindingTransactionalDraft")
        let report = AuditEngine().audit(graph: graph)
        let transactions = report.semanticValues.filter { $0.classification == .transactionalDraft }

        XCTAssertTrue(report.findings.isEmpty)
        XCTAssertEqual(transactions.count, 1)
        XCTAssertEqual(Set(transactions[0].representations.compactMap { id in
            graph.nodes.first { $0.id == id }?.kind
        }), [.binding, .state])
        XCTAssertEqual(report.metrics.manualSynchronizationEdges, 0)
        XCTAssertEqual(report.metrics.duplicatedSourcesOfTruth, 0)
        XCTAssertEqual(report.metrics.ownershipViolations, 0)
    }

    func testTransactionClassificationUsesActionTopologyNotNames() throws {
        let renamed = try auditFixture("TransactionRenamed")
        XCTAssertTrue(renamed.findings.isEmpty)
        XCTAssertEqual(
            renamed.semanticValues.filter { $0.classification == .transactionalDraft }.count,
            1
        )
        let transaction = try XCTUnwrap(renamed.semanticValues.first { $0.classification == .transactionalDraft })
        XCTAssertEqual(transaction.evidence.filter { $0.kind == "swiftui-action" }.count, 2)
        XCTAssertGreaterThanOrEqual(transaction.evidence.filter { $0.kind == "function-call" }.count, 2)

        for fixture in ["TransactionMissingDiscard", "TransactionFakeDiscard"] {
            let report = try auditFixture(fixture)
            XCTAssertEqual(
                Set(report.findings.map(\.rule)),
                [.mirroredState, .manualTwoWaySync],
                "\(fixture) must not be suppressed"
            )
            XCTAssertFalse(report.semanticValues.contains { $0.classification == .transactionalDraft })
        }
    }

    func testTunnelRequiresOneForwardedSemanticValueAndMinimumDepth() throws {
        let mismatch = try auditFixture("CallbackTunnelMismatch")
        let depthTwo = try auditFixture("TunnelDepthTwo")

        XCTAssertFalse(mismatch.findings.contains { $0.rule == .callbackBindingTunnel })
        XCTAssertFalse(depthTwo.findings.contains { $0.rule == .callbackBindingTunnel })
    }

    func testLabeledClosurePropagatesToCallbackAndFindsValueSetterPair() throws {
        let graph = try graphFixture("LabeledSetter")
        let report = AuditEngine().audit(graph: graph)
        let callback = try XCTUnwrap(graph.nodes.first {
            $0.qualifiedName == "LabeledSetter.LabeledValueEditor.onValueChanged"
        })
        let labeledPass = try XCTUnwrap(graph.edges.first {
            $0.kind == .passes && $0.to == callback.id &&
                $0.evidence.contains { $0.kind == "labeled-closure-argument" }
        })
        let finding = try XCTUnwrap(report.findings.first)

        XCTAssertEqual(graph.nodes.first { $0.id == labeledPass.from }?.kind, .closure)
        XCTAssertEqual(Set(report.findings.map(\.rule)), [.valueSetterPair])
        XCTAssertTrue(finding.edges.contains { id in
            graph.edges.contains { $0.id == id && $0.kind == .triggers }
        })
    }

    func testValueSetterPairAllowsOwnUseAndForwardButRejectsForwardOnlyAndUnrelatedCalls() throws {
        let usesAndForwardsSource = """
        import SwiftUI
        @Observable final class DualStore { var value = 0.0 }
        struct DualLeaf: View {
            let value: Double
            let update: (Double) -> Void
            var body: some View {
                Text("\\(value)").onChange(of: value) { _, next in update(next) }
            }
        }
        struct UsesAndForwards: View {
            let value: Double
            let update: (Double) -> Void
            var body: some View {
                VStack {
                    Text("\\(value)").onChange(of: value) { _, next in update(next) }
                    Text("Again").onChange(of: value) { _, next in update(next) }
                    DualLeaf(value: value, update: update)
                }
            }
        }
        struct DualHost: View {
            @State private var store = DualStore()
            var body: some View {
                UsesAndForwards(value: store.value, update: { next in store.value = next })
            }
        }
        """
        let graph = try graphTemporarySource(usesAndForwardsSource, moduleName: "UsesAndForwardsCase")
        let report = AuditEngine().audit(graph: graph)
        let repeated = try auditTemporarySource(usesAndForwardsSource, moduleName: "UsesAndForwardsCase")
        XCTAssertEqual(report.findings.count, 1)
        let finding = try XCTUnwrap(report.findings.first)
        let nodeIDs = Set(graph.nodes.map(\.id))
        let edgeIDs = Set(graph.edges.map(\.id))

        XCTAssertEqual(try report.jsonData(), try repeated.jsonData())
        XCTAssertEqual(finding.rule, .valueSetterPair)
        XCTAssertEqual(finding.severity, .medium)
        XCTAssertEqual(finding.confidence, .strongInference)
        XCTAssertTrue(finding.nodes.allSatisfy(nodeIDs.contains))
        XCTAssertTrue(finding.edges.allSatisfy(edgeIDs.contains))
        XCTAssertTrue(finding.evidence.allSatisfy { !$0.file.hasPrefix("/") && $0.startLine > 0 })
        XCTAssertEqual(finding.edges.filter { id in
            graph.edges.contains { $0.id == id && $0.kind == .triggers }
        }.count, 1)
        XCTAssertTrue(graph.edges.contains { edge in
            edge.kind == .passes && graph.nodes.first { $0.id == edge.to }?.kind == .callback
        })

        let forwardingOnly = try auditTemporarySource("""
        import SwiftUI
        @Observable final class ForwardStore { var value = 0.0 }
        struct ForwardLeaf: View {
            let value: Double
            let update: (Double) -> Void
            var body: some View {
                Text("\\(value)").onChange(of: value) { _, next in update(next) }
            }
        }
        struct ForwardOnly: View {
            let value: Double
            let update: (Double) -> Void
            var body: some View { ForwardLeaf(value: value, update: update) }
        }
        struct ForwardHost: View {
            @State private var store = ForwardStore()
            var body: some View {
                ForwardOnly(value: store.value, update: { next in store.value = next })
            }
        }
        """, moduleName: "ForwardOnlyCase")
        XCTAssertFalse(forwardingOnly.findings.contains { $0.rule == .valueSetterPair })

        let mismatchedWrite = try auditTemporarySource("""
        import SwiftUI
        @Observable final class MismatchStore { var value = 0.0; var other = 0.0 }
        struct MismatchSetter: View {
            let value: Double
            let update: (Double) -> Void
            var body: some View {
                Text("\\(value)").onChange(of: value) { _, next in update(next) }
            }
        }
        struct MismatchHost: View {
            @State private var store = MismatchStore()
            var body: some View {
                MismatchSetter(value: store.value, update: { next in store.other = next })
            }
        }
        """, moduleName: "MismatchWriteCase")
        XCTAssertFalse(mismatchedWrite.findings.contains { $0.rule == .valueSetterPair })

        let unrelatedCall = try auditTemporarySource("""
        import SwiftUI
        @Observable final class CallStore { var value = 0.0; var other = 0.0 }
        struct UnrelatedCallSetter: View {
            let value: Double
            let other: Double
            let update: (Double) -> Void
            var body: some View {
                Text("\\(value)").onChange(of: other) { _, next in print(value); update(next) }
            }
        }
        struct CallHost: View {
            @State private var store = CallStore()
            var body: some View {
                UnrelatedCallSetter(
                    value: store.value,
                    other: store.other,
                    update: { next in store.value = next }
                )
            }
        }
        """, moduleName: "UnrelatedCallCase")
        XCTAssertFalse(unrelatedCall.findings.contains { $0.rule == .valueSetterPair })

        let unrelatedSplitLine = try auditTemporarySource("""
        import SwiftUI
        @Observable final class SplitStore { var value = 0.0; var other = 0.0 }
        struct SplitCallSetter: View {
            let value: Double
            let other: Double
            let update: (Double) -> Void
            var body: some View {
                Text("\\(value)").onChange(of: other) { _, next in
                    print(value)
                    update(next)
                }
            }
        }
        struct SplitHost: View {
            @State private var store = SplitStore()
            var body: some View {
                SplitCallSetter(
                    value: store.value,
                    other: store.other,
                    update: { next in store.value = next }
                )
            }
        }
        """, moduleName: "UnrelatedSplitCallCase")
        XCTAssertFalse(unrelatedSplitLine.findings.contains { $0.rule == .valueSetterPair })
    }

    func testUnaryDerivedStateAndIdentityTransformExclusion() throws {
        let unary = try auditFixture("UnaryDerived")
        let identityTransform = try auditFixture("IdentityTransform")

        XCTAssertEqual(Set(unary.findings.map(\.rule)), [.storedDerivedState])
        XCTAssertTrue(identityTransform.findings.isEmpty)
    }

    func testCallbackTunnelReportsExactDepth() throws {
        let report = try auditFixture("CallbackTunnel")
        let finding = try XCTUnwrap(report.findings.first)

        XCTAssertEqual(finding.rule, .callbackBindingTunnel)
        XCTAssertEqual(finding.depth, 3)
        XCTAssertEqual(report.metrics.callbackTunnels, 1)
    }

    func testIntentionalTransformationUsesDerivationWithoutIdentityClustering() throws {
        let graph = try graphFixture("IntentionalTransformation")
        let report = AuditEngine().audit(graph: graph)
        let transformationEdges = graph.edges.filter {
            $0.kind == .derivesFrom && $0.evidence.contains { $0.kind == "assignment-transform" }
        }
        let identityCopies = graph.edges.filter {
            $0.kind == .copiesTo && $0.evidence.contains { $0.kind == "assignment" }
        }

        XCTAssertEqual(transformationEdges.count, 2)
        XCTAssertTrue(identityCopies.isEmpty)
        XCTAssertTrue(report.findings.isEmpty)
        XCTAssertFalse(report.findings.flatMap(\.suggestedPatterns).contains("Binding"))
    }

    func testBoundaryRulesReportExactConfidenceDepthAndVersion() throws {
        let command = try auditFixture("CommandBinding")
        let commandFinding = try XCTUnwrap(command.findings.first { $0.rule == .commandShapedBinding })
        XCTAssertEqual(command.toolVersion, ToolMetadata.version)
        XCTAssertEqual(commandFinding.confidence, .strongInference)
        XCTAssertEqual(commandFinding.severity, .medium)
        XCTAssertTrue(commandFinding.suggestedPatterns.contains("action-closure"))

        let factory = try XCTUnwrap(auditFixture("BindingFactory").findings.first)
        XCTAssertEqual(factory.rule, .bindingFactory)
        XCTAssertEqual(factory.confidence, .candidate)

        let tunnel = try XCTUnwrap(auditFixture("ObservableModelTunnel").findings.first)
        XCTAssertEqual(tunnel.rule, .observableModelTunnel)
        XCTAssertEqual(tunnel.confidence, .strongInference)
        XCTAssertEqual(tunnel.depth, 2)

        let broad = try XCTUnwrap(auditFixture("BroadObservableInput").findings.first)
        XCTAssertEqual(broad.rule, .broadObservableInput)
        XCTAssertEqual(broad.confidence, .candidate)
    }

    func testLogicalSourceMetricsCountRootsInsteadOfBindingRepresentations() throws {
        for fixture in ["FocusedBindingChain", "ObservableModelTunnel"] {
            let graph = try graphFixture(fixture)
            let report = AuditEngine().audit(graph: graph)
            XCTAssertEqual(report.metrics.duplicatedSourcesOfTruth, 0, fixture)
            XCTAssertTrue(
                report.semanticValues.allSatisfy { LogicalSourceCounter.count(for: $0, in: graph) <= 1 },
                fixture
            )
        }

        let mirroredGraph = try graphFixture("BindingMirroredLocally")
        let mirrored = AuditEngine().audit(graph: mirroredGraph)
        XCTAssertEqual(mirrored.metrics.duplicatedSourcesOfTruth, 1)
        XCTAssertTrue(mirrored.semanticValues.contains {
            LogicalSourceCounter.count(for: $0, in: mirroredGraph) == 2
        })
    }

    func testFindingsHaveValidGraphEndpointsAndRelativeEvidence() throws {
        let findingFixtures = expectations.filter { !$0.rules.isEmpty }.map(\.fixture) + [
            "LabeledSetter", "UnaryDerived", "TransactionMissingDiscard", "TransactionFakeDiscard",
        ]
        for fixture in findingFixtures {
            let graph = try graphFixture(fixture)
            let report = AuditEngine().audit(graph: graph)
            let nodeIDs = Set(graph.nodes.map(\.id))
            let edgeIDs = Set(graph.edges.map(\.id))
            for finding in report.findings {
                XCTAssertTrue(finding.nodes.allSatisfy(nodeIDs.contains))
                XCTAssertTrue(finding.edges.allSatisfy(edgeIDs.contains))
                XCTAssertFalse(finding.evidence.isEmpty)
                XCTAssertTrue(finding.evidence.allSatisfy {
                    !$0.file.hasPrefix("/") && $0.startLine >= 1 && $0.endLine >= $0.startLine
                })
            }
        }
    }

    func testAuditJSONAndFindingIDsAreStableAcrossLeadingLines() throws {
        for fixture in ["BidirectionalOnChange", "BindingMirroredLocally"] {
            let sourceURL = fixtureURL(fixture).appendingPathComponent("Fixture.swift")
            let source = try String(contentsOf: sourceURL, encoding: .utf8)
            let first = try auditTemporarySource(source, moduleName: "LineStable")
            let repeated = try auditTemporarySource(source, moduleName: "LineStable")
            let shifted = try auditTemporarySource("\n\n\n" + source, moduleName: "LineStable")

            XCTAssertEqual(try first.jsonData(), try repeated.jsonData())
            XCTAssertEqual(first.findings.map(\.id), shifted.findings.map(\.id))
            XCTAssertEqual(first.findings.map(\.rule), shifted.findings.map(\.rule))
            XCTAssertNotEqual(first.findings.flatMap(\.evidence), shifted.findings.flatMap(\.evidence))
        }
    }

    func testMetricsReflectDetectedTopology() throws {
        let mirror = try auditFixture("BidirectionalOnChange")
        XCTAssertEqual(mirror.metrics.manualSynchronizationEdges, 2)
        XCTAssertEqual(mirror.metrics.duplicatedSourcesOfTruth, 1)
        XCTAssertEqual(mirror.metrics.ownershipViolations, 1)

        let derived = try auditFixture("DerivedState")
        XCTAssertEqual(derived.metrics.derivedMutableValues, 1)

        let binding = try auditFixture("GoodDirectBinding")
        XCTAssertGreaterThan(binding.metrics.bindingEdges, 0)
        XCTAssertEqual(binding.metrics.manualSynchronizationEdges, 0)
    }

    private func auditFixture(_ name: String) throws -> AuditReport {
        AuditEngine().audit(graph: try graphFixture(name))
    }

    private func graphFixture(_ name: String) throws -> SemanticGraph {
        try GraphScanner().scan(path: fixtureURL(name).path)
    }

    private func fixtureURL(_ name: String) -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures/RuleTests/\(name)")
    }

    private func auditTemporarySource(_ source: String, moduleName: String) throws -> AuditReport {
        AuditEngine().audit(graph: try graphTemporarySource(source, moduleName: moduleName))
    }

    private func graphTemporarySource(_ source: String, moduleName: String) throws -> SemanticGraph {
        let parent = FileManager.default.temporaryDirectory
            .appendingPathComponent("swiftui-audit-rule-test-\(UUID().uuidString)")
        let root = parent.appendingPathComponent(moduleName)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: parent) }
        try source.write(to: root.appendingPathComponent("Fixture.swift"), atomically: true, encoding: .utf8)
        return try GraphScanner().scan(path: root.path)
    }
}
