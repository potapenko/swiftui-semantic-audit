import AuditCore
import AuditRules
import SwiftSyntaxFrontend
import XCTest

final class ArchitectureRuleTests: XCTestCase {
    func testConfiguredPositiveFixtureCoversEveryArchitectureRuleWithDominance() throws {
        let graph = try configuredGraph(at: positiveFixture)
        let report = AuditEngine().audit(graph: graph)
        let architectureRules = Set(RuleID.allCases.dropFirst(10))
        let emitted = Set(report.findings.map(\.rule)).intersection(architectureRules)

        XCTAssertEqual(emitted, architectureRules)
        XCTAssertEqual(report.schemaVersion, 2)
        XCTAssertEqual(report.configurationDigest, graph.configurationDigest)
        XCTAssertNotEqual(graph.configurationDigest, "none")

        let grouped = Dictionary(grouping: report.findings, by: \.rule)
        for generic in grouped[.modelAwareDescendant] ?? [] {
            XCTAssertFalse((grouped[.multiOwnerComponent] ?? []).contains {
                !Set(generic.nodes).isDisjoint(with: $0.nodes)
            })
        }
        for generic in grouped[.geometryDrivenProductLayout] ?? [] {
            let specifics = [
                RuleID.geometryEscapesLayoutBoundary,
                .geometryTriggeredModelEffect,
                .manualPositioningAsLayout,
            ].flatMap { grouped[$0] ?? [] }
            XCTAssertFalse(specifics.contains {
                !Set(generic.edges).isDisjoint(with: $0.edges)
            })
        }
        assertFindingIntegrity(report, graph: graph)
    }

    func testNegativeFixturePreservesArchitectureExceptions() throws {
        let graph = try configuredGraph(at: negativeFixture)
        let report = AuditEngine().audit(graph: graph)
        let architectureRules = Set(RuleID.allCases.dropFirst(10))

        XCTAssertTrue(Set(report.findings.map(\.rule)).isDisjoint(with: architectureRules))
    }

    func testConfigurationIsCanonicalExactAndDoesNotWalkAncestors() throws {
        let first = try AnalysisConfiguration.load(
            explicitURL: positiveFixture.appendingPathComponent(".swiftui-audit.json"),
            sourceURL: positiveFixture
        )
        let reordered = try AnalysisConfiguration(
            compositionRoots: ["ArchitectureTests.AppRoot", "ArchitectureTests.AppRoot"],
            typeRoles: [
                "ArchitectureTests.SearchRepository": .repository,
                "ArchitectureTests.OtherModel": .featureModel,
                "ArchitectureTests.FeatureModel": .featureModel,
                "ArchitectureTests.CommandRouter": .effectSink,
                "ArchitectureTests.AppModel": .applicationModel,
            ],
            typeFeatures: [
                "ArchitectureTests.OtherModel": "feature-b",
                "ArchitectureTests.FeatureModel": "feature-a",
            ],
            pathFeatures: ["Features/A/": "feature-a"],
            passiveEnvironmentValues: ["locale", "locale"]
        )
        XCTAssertEqual(try XCTUnwrap(first).digest, reordered.digest)

        let temporary = FileManager.default.temporaryDirectory
            .appendingPathComponent("swiftui-audit-config-test-\(UUID().uuidString)", isDirectory: true)
        let child = temporary.appendingPathComponent("Child", isDirectory: true)
        try FileManager.default.createDirectory(at: child, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporary) }
        try Data("{\"schemaVersion\":1}".utf8).write(
            to: temporary.appendingPathComponent(".swiftui-audit.json")
        )
        try Data("struct Value {}".utf8).write(to: child.appendingPathComponent("Value.swift"))
        XCTAssertNil(try AnalysisConfiguration.load(explicitURL: nil, sourceURL: child))

        let invalid = child.appendingPathComponent("invalid.json")
        try Data("{\"schemaVersion\":1,\"invented\":true}".utf8).write(to: invalid)
        XCTAssertThrowsError(try AnalysisConfiguration.load(explicitURL: invalid, sourceURL: child)) {
            XCTAssertEqual($0 as? AnalysisConfigurationError, .unknownFields(["invented"]))
        }

        let duplicate = child.appendingPathComponent("duplicate.json")
        try Data("{\"schemaVersion\":1,\"typeRoles\":{\"App.Model\":\"service\",\"App.Model\":\"repository\"}}".utf8)
            .write(to: duplicate)
        XCTAssertThrowsError(try AnalysisConfiguration.load(explicitURL: duplicate, sourceURL: child))
    }

    func testSameNamedFileLocalDeclarationsRemainDistinctAndFileScoped() throws {
        let temporary = FileManager.default.temporaryDirectory
            .appendingPathComponent("CollisionFixture", isDirectory: true)
        try FileManager.default.createDirectory(at: temporary, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporary) }
        let source = """
        import SwiftUI
        private struct LocalView: View {
            @State var value = 0
            var body: some View { Text("\\(value)") }
        }
        """
        try source.write(to: temporary.appendingPathComponent("A.swift"), atomically: true, encoding: .utf8)
        try source.write(to: temporary.appendingPathComponent("B.swift"), atomically: true, encoding: .utf8)

        let graph = try GraphScanner().scan(path: temporary.path)
        let localViews = graph.nodes.filter { $0.qualifiedName == "CollisionFixture.LocalView" }
        let values = graph.nodes.filter { $0.qualifiedName == "CollisionFixture.LocalView.value" }

        XCTAssertEqual(localViews.count, 2)
        XCTAssertEqual(Set(localViews.map(\.id)).count, 2)
        XCTAssertEqual(values.count, 2)
        XCTAssertEqual(Set(values.map(\.id)).count, 2)
        for file in ["A.swift", "B.swift"] {
            let view = try XCTUnwrap(localViews.first { $0.evidence.contains { $0.file == file } })
            let value = try XCTUnwrap(values.first { $0.evidence.contains { $0.file == file } })
            XCTAssertTrue(graph.edges.contains { $0.kind == .owns && $0.from == view.id && $0.to == value.id })
        }
    }

    private func configuredGraph(at fixture: URL) throws -> SemanticGraph {
        let graph = try GraphScanner().scan(path: fixture.path)
        let configuration = try XCTUnwrap(AnalysisConfiguration.load(
            explicitURL: nil,
            sourceURL: fixture
        ))
        return configuration.applying(to: graph)
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

    private var projectRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private var positiveFixture: URL {
        projectRoot.appendingPathComponent("Tests/Fixtures/ArchitectureTests", isDirectory: true)
    }

    private var negativeFixture: URL {
        projectRoot.appendingPathComponent("Tests/Fixtures/ArchitectureNegative", isDirectory: true)
    }
}
