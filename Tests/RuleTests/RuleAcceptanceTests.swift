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

        XCTAssertEqual(graph.nodes.first { $0.id == labeledPass.from }?.kind, .closure)
        XCTAssertEqual(Set(report.findings.map(\.rule)), [.valueSetterPair])
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
        let sourceURL = fixtureURL("BidirectionalOnChange").appendingPathComponent("Fixture.swift")
        let source = try String(contentsOf: sourceURL, encoding: .utf8)
        let first = try auditTemporarySource(source, moduleName: "LineStable")
        let second = try auditTemporarySource("\n\n\n" + source, moduleName: "LineStable")

        XCTAssertEqual(first.findings.map(\.id), second.findings.map(\.id))
        XCTAssertEqual(first.findings.map(\.rule), second.findings.map(\.rule))
        XCTAssertNotEqual(first.findings.flatMap(\.evidence), second.findings.flatMap(\.evidence))
        XCTAssertEqual(try first.jsonData(), try first.jsonData())
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
        let parent = FileManager.default.temporaryDirectory
            .appendingPathComponent("swiftui-audit-rule-test-\(UUID().uuidString)")
        let root = parent.appendingPathComponent(moduleName)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: parent) }
        try source.write(to: root.appendingPathComponent("Fixture.swift"), atomically: true, encoding: .utf8)
        return AuditEngine().audit(graph: try GraphScanner().scan(path: root.path))
    }
}
