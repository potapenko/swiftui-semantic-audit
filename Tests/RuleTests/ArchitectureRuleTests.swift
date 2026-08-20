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
            let specifics = (grouped[.multiOwnerComponent] ?? []) +
                (grouped[.reusableComponentOwnerDependency] ?? [])
            XCTAssertFalse(specifics.contains {
                sameBoundaryPath(generic, $0)
            })
        }
        for generic in grouped[.broadObservableInput] ?? [] {
            XCTAssertFalse((grouped[.reusableComponentOwnerDependency] ?? []).contains {
                sameBoundaryPath(generic, $0)
            })
        }
        for reusable in grouped[.reusableComponentOwnerDependency] ?? [] {
            XCTAssertFalse((grouped[.multiOwnerComponent] ?? []).contains {
                sameBoundaryPath(reusable, $0)
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
            schemaVersion: 2,
            compositionRoots: ["ArchitectureTests.AppRoot", "ArchitectureTests.AppRoot"],
            viewRoles: [
                "ArchitectureTests.ReusableBindingLeaf": .reusableComponent,
                "ArchitectureTests.ReusableBindableLeaf": .reusableComponent,
                "ArchitectureTests.MultiOwnerLeaf": .reusableComponent,
                "ArchitectureTests.ModelLeaf": .reusableComponent,
                "ArchitectureTests.EnvironmentOwnerLeaf": .reusableComponent,
                "ArchitectureTests.EnvironmentComponentLeaf": .reusableComponent,
                "ArchitectureTests.AppRoot": .screen,
            ],
            typeRoles: [
                "ArchitectureTests.SearchRepository": .repository,
                "ArchitectureTests.OtherModel": .featureModel,
                "ArchitectureTests.FeatureModel": .featureModel,
                "ArchitectureTests.ComponentModel": .componentModel,
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

    func testSchemaOneDigestIsStableAndSchemaTwoRolesAreCanonical() throws {
        let legacy = try XCTUnwrap(AnalysisConfiguration.load(
            explicitURL: negativeFixture.appendingPathComponent(".swiftui-audit.json"),
            sourceURL: negativeFixture
        ))
        XCTAssertEqual(legacy.schemaVersion, 1)
        XCTAssertEqual(legacy.digest, "547239c1f16b07d016a306b0dc37278a813bfb02893c30d4959990022189940a")
        XCTAssertThrowsError(try AnalysisConfiguration(
            viewRoles: ["App.Row": .reusableComponent]
        ))
        XCTAssertThrowsError(try AnalysisConfiguration(
            typeRoles: ["App.RowModel": .componentModel]
        ))

        let first = try AnalysisConfiguration(
            schemaVersion: 2,
            viewRoles: ["App.Screen": .screen, "App.Row": .reusableComponent],
            typeRoles: ["App.RowModel": .componentModel]
        )
        let reordered = try AnalysisConfiguration(
            schemaVersion: 2,
            viewRoles: ["App.Row": .reusableComponent, "App.Screen": .screen],
            typeRoles: ["App.RowModel": .componentModel]
        )
        XCTAssertEqual(first.digest, reordered.digest)
        XCTAssertNotEqual(first.digest, legacy.digest)
    }

    func testReusableOwnerRuleCoversPlainBindableBindingAndEnvironmentBoundaries() throws {
        let graph = try configuredGraph(at: positiveFixture)
        let report = AuditEngine().audit(graph: graph)
        let findings = report.findings.filter { $0.rule == .reusableComponentOwnerDependency }

        XCTAssertEqual(
            Set(findings.flatMap { viewNames(in: $0, graph: graph) }),
            [
                "ArchitectureTests.EnvironmentComponentLeaf",
                "ArchitectureTests.EnvironmentOwnerLeaf",
                "ArchitectureTests.ModelLeaf",
                "ArchitectureTests.ReusableBindableLeaf",
                "ArchitectureTests.ReusableBindingLeaf",
            ]
        )
        XCTAssertFalse(findings.contains {
            viewNames(in: $0, graph: graph).contains("ArchitectureTests.MultiOwnerLeaf")
        })
    }

    func testReusableOwnerRulePreservesExplicitLifetimeAndRoleExceptions() throws {
        let temporary = FileManager.default.temporaryDirectory
            .appendingPathComponent("swiftui-audit-component-exceptions-\(UUID().uuidString)", isDirectory: true)
        let fixture = temporary.appendingPathComponent("ComponentRoleFixture", isDirectory: true)
        try FileManager.default.createDirectory(at: fixture, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporary) }
        let source = """
        import SwiftUI
        final class AppModel { var value = 0 }
        final class ItemModel { var value = 0 }
        final class RoleLikeModel { var value = 0 }
        struct ScreenOwner: View { let model: AppModel; var body: some View { Text("screen") } }
        struct ContainerOwner: View { let model: AppModel; var body: some View { Text("container") } }
        struct ExplicitItemLeaf: View { let model: ItemModel; var body: some View { Text("item") } }
        struct LocalItemLeaf: View {
            @State private var model = ItemModel()
            var body: some View { Text("local") }
        }
        struct PassiveLeaf: View {
            @Environment var appEnvironment: AppModel
            var body: some View { Text("passive") }
        }
        struct UnclassifiedLeaf: View { let model: AppModel; var body: some View { Text("unknown") } }
        struct RoleLikeReusableLeaf: View {
            let model: RoleLikeModel
            var body: some View { Text("spelling") }
        }
        struct FocusedLeaf: View {
            let value: Int
            @Binding var selection: Int
            let action: () -> Void
            var body: some View { Button("Run", action: action) }
        }
        """
        try source.write(to: fixture.appendingPathComponent("Fixture.swift"), atomically: true, encoding: .utf8)
        let configuration = try AnalysisConfiguration(
            schemaVersion: 2,
            viewRoles: [
                "ComponentRoleFixture.ScreenOwner": .screen,
                "ComponentRoleFixture.ContainerOwner": .container,
                "ComponentRoleFixture.ExplicitItemLeaf": .reusableComponent,
                "ComponentRoleFixture.LocalItemLeaf": .reusableComponent,
                "ComponentRoleFixture.PassiveLeaf": .reusableComponent,
                "ComponentRoleFixture.RoleLikeReusableLeaf": .reusableComponent,
                "ComponentRoleFixture.FocusedLeaf": .reusableComponent,
            ],
            typeRoles: [
                "ComponentRoleFixture.AppModel": .applicationModel,
                "ComponentRoleFixture.ItemModel": .componentModel,
            ],
            passiveEnvironmentValues: ["appEnvironment"]
        )
        let graph = configuration.applying(to: try GraphScanner().scan(path: fixture.path))
        let report = AuditEngine().audit(graph: graph)

        XCTAssertTrue(report.findings.filter { $0.rule == .reusableComponentOwnerDependency }.isEmpty)
        XCTAssertTrue(graph.nodes.first {
            $0.qualifiedName == "ComponentRoleFixture.ScreenOwner"
        }?.roles.contains("screen") == true)
        XCTAssertTrue(graph.nodes.first {
            $0.qualifiedName == "ComponentRoleFixture.ItemModel"
        }?.roles.contains("component-model") == true)
        XCTAssertTrue(graph.nodes.first {
            $0.qualifiedName == "ComponentRoleFixture.PassiveLeaf.appEnvironment"
        }?.roles.contains("passive-environment") == true)
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

    private func viewNames(in finding: AuditFinding, graph: SemanticGraph) -> Set<String> {
        Set(finding.nodes.compactMap { id in
            graph.nodes.first { $0.id == id && $0.kind == .view }?.qualifiedName
        })
    }

    private func sameBoundaryPath(_ lhs: AuditFinding, _ rhs: AuditFinding) -> Bool {
        !Set(lhs.edges).isDisjoint(with: rhs.edges) ||
            Set(lhs.nodes).intersection(rhs.nodes).count >= 2
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
