import AuditCore
import AuditRules
import SwiftSyntaxFrontend
import XCTest

final class RealProjectPatternTests: XCTestCase {
    func testRealProjectPatternMatrixIsExactAndGoodFilesStayClean() throws {
        let (graph, report) = try auditFixture()

        XCTAssertEqual(report.schemaVersion, 2)
        XCTAssertEqual(report.resolution, "syntax-only")
        XCTAssertNotEqual(report.configurationDigest, "none")
        XCTAssertEqual(report.findings.count, 34)

        let expectedByFile: [String: [RuleID: Int]] = [
            "Bad/FeatureProfile/BadBoundaryViews.swift": [
                .broadObservableInput: 1,
                .crossFeatureOwnerDependency: 1,
                .environmentCommandRouter: 1,
                .modelAwareDescendant: 1,
                .multiOwnerComponent: 2,
                .observableModelTunnel: 1,
                .serviceOrRepositoryInView: 3,
                .viewOwnedExternalEffect: 2,
            ],
            "Bad/Lifecycle/BadLifecycleViews.swift": [
                .hiddenCommandInLifecycle: 1,
                .imperativeFocusLifecycle: 1,
                .manualOwnerSynchronization: 1,
                .manualTwoWaySync: 1,
                .selectionCorrectiveLoop: 1,
            ],
            "Bad/Layout/BadLayoutViews.swift": [
                .geometryDrivenProductLayout: 1,
                .geometryEscapesLayoutBoundary: 1,
                .geometryTriggeredModelEffect: 1,
                .gestureButtonEmulation: 1,
                .hiddenCommandInLifecycle: 1,
                .manualPositioningAsLayout: 1,
            ],
            "Bad/Platform/BadPlatformViews.swift": [
                .directGlobalPlatformCommand: 1,
                .imperativePlatformViewUpdate: 1,
                .previewRequiresAppComposition: 1,
            ],
            "Bad/StateFlow/CommandBindingView.swift": [
                .broadObservableInput: 2,
                .commandShapedBinding: 1,
                .multiOwnerComponent: 1,
                .multiSourceBinding: 1,
                .viewOwnedExternalEffect: 1,
            ],
            "Bad/StateFlow/MirroredEditor.swift": [
                .manualTwoWaySync: 1,
                .mirroredState: 1,
            ],
        ]

        var actualByFile: [String: [RuleID: Int]] = [:]
        for finding in report.findings {
            let files = Set(finding.evidence.map(\.file))
            XCTAssertEqual(files.count, 1, finding.rule.rawValue)
            let file = try XCTUnwrap(files.first)
            actualByFile[file, default: [:]][finding.rule, default: 0] += 1
            XCTAssertFalse(file.hasPrefix("Good/"), "good counterpart emitted \(finding.rule.rawValue)")
        }
        XCTAssertEqual(actualByFile, expectedByFile)

        let tunnel = try XCTUnwrap(report.findings.first { $0.rule == .observableModelTunnel })
        XCTAssertEqual(tunnel.depth, 2)
        XCTAssertEqual(
            viewNames(in: tunnel, graph: graph),
            [
                "RealProjectPatterns.BadAppRoot",
                "RealProjectPatterns.BadModelContainer",
                "RealProjectPatterns.BadModelLeaf",
            ]
        )
        let crossFeature = try XCTUnwrap(report.findings.first { $0.rule == .crossFeatureOwnerDependency })
        XCTAssertEqual(viewNames(in: crossFeature, graph: graph), ["RealProjectPatterns.BadCrossFeatureLeaf"])

        assertSeverityAndConfidence(report)
        assertFindingIntegrity(report, graph: graph)
    }

    func testRealProjectPatternAuditIsByteStable() throws {
        let (firstGraph, firstReport) = try auditFixture()
        let (secondGraph, secondReport) = try auditFixture()

        XCTAssertEqual(try firstGraph.jsonData(), try secondGraph.jsonData())
        XCTAssertEqual(try firstReport.jsonData(), try secondReport.jsonData())
    }

    func testFortyCleanDistractorFilesPreserveExactFindings() throws {
        let (_, baseline) = try auditFixture()
        let temporary = FileManager.default.temporaryDirectory
            .appendingPathComponent("swiftui-audit-real-patterns-\(UUID().uuidString)", isDirectory: true)
        let copiedFixture = temporary.appendingPathComponent("RealProjectPatterns", isDirectory: true)
        try FileManager.default.createDirectory(at: temporary, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporary) }
        try FileManager.default.copyItem(at: fixtureRoot, to: copiedFixture)

        let distractors = copiedFixture.appendingPathComponent("Good/Distractors", isDirectory: true)
        try FileManager.default.createDirectory(at: distractors, withIntermediateDirectories: true)
        for index in 0 ..< 40 {
            let source = """
            import SwiftUI

            struct GoodDistractor\(index): View {
                @State private var expanded = false

                var body: some View {
                    Button("Toggle") { expanded.toggle() }
                }
            }
            """
            try source.write(
                to: distractors.appendingPathComponent("GoodDistractor\(index).swift"),
                atomically: true,
                encoding: .utf8
            )
        }

        let graph = try configuredGraph(at: copiedFixture)
        let expanded = AuditEngine().audit(graph: graph)

        XCTAssertEqual(expanded.configurationDigest, baseline.configurationDigest)
        XCTAssertEqual(expanded.findings, baseline.findings)
        assertFindingIntegrity(expanded, graph: graph)
    }

    private func auditFixture() throws -> (SemanticGraph, AuditReport) {
        let graph = try configuredGraph(at: fixtureRoot)
        return (graph, AuditEngine().audit(graph: graph))
    }

    private func configuredGraph(at fixture: URL) throws -> SemanticGraph {
        let graph = try GraphScanner().scan(path: fixture.path)
        let configuration = try XCTUnwrap(AnalysisConfiguration.load(
            explicitURL: fixture.appendingPathComponent(".swiftui-audit.json"),
            sourceURL: fixture
        ))
        return configuration.applying(to: graph)
    }

    private func viewNames(in finding: AuditFinding, graph: SemanticGraph) -> Set<String> {
        Set(finding.nodes.compactMap { id in
            graph.nodes.first { $0.id == id && $0.kind == .view }?.qualifiedName
        })
    }

    private func assertSeverityAndConfidence(_ report: AuditReport) {
        let candidateRules: Set<RuleID> = [
            .broadObservableInput,
            .environmentCommandRouter,
            .geometryDrivenProductLayout,
            .hiddenCommandInLifecycle,
            .manualPositioningAsLayout,
            .modelAwareDescendant,
            .previewRequiresAppComposition,
            .viewOwnedExternalEffect,
        ]
        let highRules: Set<RuleID> = [
            .crossFeatureOwnerDependency,
            .directGlobalPlatformCommand,
            .geometryTriggeredModelEffect,
            .imperativePlatformViewUpdate,
            .manualOwnerSynchronization,
            .manualTwoWaySync,
            .mirroredState,
            .multiOwnerComponent,
            .selectionCorrectiveLoop,
            .serviceOrRepositoryInView,
            .viewOwnedExternalEffect,
        ]

        for finding in report.findings {
            XCTAssertEqual(
                finding.confidence,
                candidateRules.contains(finding.rule) ? .candidate : .strongInference,
                finding.rule.rawValue
            )
            XCTAssertEqual(
                finding.severity,
                highRules.contains(finding.rule) ? .high : .medium,
                finding.rule.rawValue
            )
        }
    }

    private func assertFindingIntegrity(_ report: AuditReport, graph: SemanticGraph) {
        let nodeIDs = Set(graph.nodes.map(\.id))
        let edgeIDs = Set(graph.edges.map(\.id))
        for finding in report.findings {
            XCTAssertFalse(finding.evidence.isEmpty, finding.rule.rawValue)
            XCTAssertTrue(finding.nodes.allSatisfy(nodeIDs.contains), finding.rule.rawValue)
            XCTAssertTrue(finding.edges.allSatisfy(edgeIDs.contains), finding.rule.rawValue)
            XCTAssertTrue(finding.evidence.allSatisfy {
                !$0.file.hasPrefix("/") && $0.startLine > 0 && $0.endLine >= $0.startLine
            }, finding.rule.rawValue)
        }
    }

    private var fixtureRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures/RealProjectPatterns", isDirectory: true)
    }
}
