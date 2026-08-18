import AuditCore
import AuditRules
import Foundation
import SemanticDiff
import SnapshotStore
import SwiftSyntaxFrontend
import XCTest

final class SemanticDiffTests: XCTestCase {
    func testComparisonRejectsDifferentConfigurationDigests() throws {
        func input(_ digest: String) -> LoadedSemanticInput {
            let graph = SemanticGraph(configurationDigest: digest, nodes: [], edges: [])
            let report = AuditReport(
                resolution: "syntax-only",
                configurationDigest: digest,
                metrics: AuditMetrics(
                    mutableSemanticValues: 0,
                    stateRepresentations: 0,
                    bindingEdges: 0,
                    manualSynchronizationEdges: 0,
                    callbackTunnels: 0,
                    derivedMutableValues: 0,
                    duplicatedSourcesOfTruth: 0,
                    ownershipViolations: 0
                ),
                semanticValues: [],
                findings: []
            )
            let manifest = SnapshotManifest(
                swiftVersion: "test",
                repositoryRevision: "test",
                generatedFrom: ".",
                configurationDigest: digest
            )
            return LoadedSemanticInput(
                snapshot: SemanticSnapshot(manifest: manifest, graph: graph, report: report),
                identity: digest
            )
        }

        XCTAssertThrowsError(
            try SemanticInputLoader().validateMatchingResolution(base: input("a"), current: input("b"))
        ) {
            XCTAssertEqual($0 as? SemanticInputError, .configurationMismatch(baseline: "a", current: "b"))
        }
    }

    func testUnchangedSnapshotHasNoChangesAndStableJSON() throws {
        let snapshot = syntheticPair().base
        let report = SemanticDiffEngine().compare(base: snapshot, current: snapshot)

        XCTAssertTrue(report.changes.isEmpty)
        XCTAssertTrue(report.newFindings.isEmpty)
        XCTAssertTrue(report.resolvedFindings.isEmpty)
        XCTAssertEqual(report.beforeMetrics, report.afterMetrics)
        XCTAssertEqual(try report.jsonData(), try report.jsonData())
    }

    func testExactMinimumChangeKindMatrix() {
        let pair = syntheticPair()
        let report = SemanticDiffEngine().compare(base: pair.base, current: pair.current)

        XCTAssertEqual(Set(report.changes.map(\.kind)), Set(SemanticChangeKind.allCases))
        XCTAssertEqual(report.newFindings.map(\.rule), [.manualTwoWaySync])
        XCTAssertEqual(report.resolvedFindings.map(\.rule), [.manualTwoWaySync])
        XCTAssertEqual(report.affectedSemanticValues.first { $0.id == "value:common" }?.beforeSourceCount, 2)
        XCTAssertEqual(report.affectedSemanticValues.first { $0.id == "value:common" }?.afterSourceCount, 1)
    }

    func testMirroredManualToDirectBindingImprovesTopologyWithoutNewHighFinding() throws {
        let before = try scanSource(Self.mirroredSource, container: "before")
        let after = try scanSource(Self.bindingSource, container: "after")
        let report = SemanticDiffEngine().compare(base: before, current: after)

        XCTAssertGreaterThan(report.beforeMetrics.manualSynchronizationEdges, report.afterMetrics.manualSynchronizationEdges)
        XCTAssertGreaterThan(report.beforeMetrics.duplicatedSourcesOfTruth, report.afterMetrics.duplicatedSourcesOfTruth)
        XCTAssertLessThan(report.beforeMetrics.bindingEdges, report.afterMetrics.bindingEdges)
        XCTAssertTrue(report.changes.contains { $0.kind == .bindingAdded })
        XCTAssertTrue(report.changes.contains { $0.kind == .manualSyncRemoved })
        XCTAssertTrue(report.changes.contains { $0.kind == .sourceOfTruthCountChanged })
        XCTAssertEqual(Set(report.resolvedFindings.map(\.rule)), [.manualTwoWaySync, .mirroredState])
        XCTAssertFalse(report.newFindings.contains { $0.severity == .high })
    }

    func testStrongValueCountDoesNotMergeUnrelatedRenamedRepresentations() {
        let pair = syntheticPair()
        let report = SemanticDiffEngine().compare(base: pair.base, current: pair.current)
        let removed = report.affectedSemanticValues.filter { !$0.beforeRepresentations.isEmpty && $0.afterRepresentations.isEmpty }
        let added = report.affectedSemanticValues.filter { $0.beforeRepresentations.isEmpty && !$0.afterRepresentations.isEmpty }

        XCTAssertFalse(removed.contains { delta in added.contains { $0.id == delta.id } })
        XCTAssertTrue(report.affectedSemanticValues.contains { $0.id == "value:common" })
    }

    func testSourceCountUsesStrongClusterContinuityAndIgnoresAbsentZero() {
        let owner = node("M.Owner", .view)
        let first = node("M.Owner.first", .state)
        let second = node("M.Owner.second", .state)
        let binding = node("M.Owner.binding", .binding)
        let firstValue = NormalizedSemanticValue(
            id: StableID.semanticValue(representations: [first.id]),
            representations: [first.id], relationEdges: [], confidence: .deterministic,
            classification: nil, evidence: first.evidence
        )
        let twoValue = NormalizedSemanticValue(
            id: StableID.semanticValue(representations: [first.id, second.id]),
            representations: [first.id, second.id], relationEdges: [], confidence: .deterministic,
            classification: nil, evidence: first.evidence + second.evidence
        )
        let bindingValue = NormalizedSemanticValue(
            id: StableID.semanticValue(representations: [binding.id]),
            representations: [binding.id], relationEdges: [], confidence: .deterministic,
            classification: nil, evidence: binding.evidence
        )
        let one = snapshot(graph: SemanticGraph(nodes: [owner, first], edges: []), values: [firstValue], findings: [], duplicated: 0)
        let two = snapshot(graph: SemanticGraph(nodes: [owner, first, second], edges: []), values: [twoValue], findings: [], duplicated: 1)
        let empty = snapshot(graph: SemanticGraph(nodes: [owner], edges: []), values: [], findings: [], duplicated: 0)
        let bindingOnly = snapshot(graph: SemanticGraph(nodes: [owner, binding], edges: []), values: [bindingValue], findings: [], duplicated: 0)

        assertSourceCount(SemanticDiffEngine().compare(base: one, current: two), before: 1, after: 2, beforeRepresentations: 1, afterRepresentations: 2)
        assertSourceCount(SemanticDiffEngine().compare(base: two, current: one), before: 2, after: 1, beforeRepresentations: 2, afterRepresentations: 1)
        assertSourceCount(SemanticDiffEngine().compare(base: empty, current: one), before: 0, after: 1, beforeRepresentations: 0, afterRepresentations: 1)
        XCTAssertFalse(SemanticDiffEngine().compare(base: empty, current: bindingOnly).changes.contains { $0.kind == .sourceOfTruthCountChanged })
        XCTAssertFalse(SemanticDiffEngine().compare(base: bindingOnly, current: empty).changes.contains { $0.kind == .sourceOfTruthCountChanged })
    }

    func testSourceCountTreatsFocusedBindingChainAsOneRootAndBorrowedMirrorAsTwo() {
        let owner = node("M.Owner", .view)
        let state = node("M.Owner.value", .state)
        let middle = boundaryNode("M.Middle.value", .binding)
        let leaf = boundaryNode("M.Leaf.value", .binding)
        let value = NormalizedSemanticValue(
            id: StableID.semanticValue(representations: [state.id, middle.id, leaf.id]),
            representations: [state.id, middle.id, leaf.id],
            relationEdges: [], confidence: .strongInference, classification: nil,
            evidence: state.evidence + middle.evidence + leaf.evidence
        )
        let focusedGraph = SemanticGraph(nodes: [owner, state, middle, leaf], edges: [
            edge(.passes, state, middle, "root-to-middle"),
            edge(.passes, middle, leaf, "middle-to-leaf"),
        ])
        let mirroredGraph = SemanticGraph(nodes: [owner, state, middle, leaf], edges: [
            edge(.copiesTo, middle, state, "borrowed-to-local"),
            edge(.copiesTo, state, middle, "local-to-borrowed"),
        ])

        XCTAssertEqual(LogicalSourceCounter.count(for: value, in: focusedGraph), 1)
        XCTAssertEqual(LogicalSourceCounter.count(for: value, in: mirroredGraph), 2)

        let base = snapshot(graph: focusedGraph, values: [value], findings: [], duplicated: 0)
        let current = snapshot(graph: mirroredGraph, values: [value], findings: [], duplicated: 1)
        assertSourceCount(
            SemanticDiffEngine().compare(base: base, current: current),
            before: 1, after: 2, beforeRepresentations: 3, afterRepresentations: 3
        )
    }

    func testWrapperKindTransitionPreservesDeclarationContinuityAndOwnership() {
        let owner = node("M.Editor", .view)
        let binding = node("M.Editor.value", .binding)
        let state = node("M.Editor.value", .state)
        let base = snapshot(
            graph: SemanticGraph(nodes: [owner, binding], edges: [edge(.binds, owner, binding, "owner")]),
            values: [value(binding)], findings: [], duplicated: 0
        )
        let current = snapshot(
            graph: SemanticGraph(nodes: [owner, state], edges: [edge(.owns, owner, state, "owner")]),
            values: [value(state)], findings: [], duplicated: 0
        )

        let forward = SemanticDiffEngine().compare(base: base, current: current)
        let reverse = SemanticDiffEngine().compare(base: current, current: base)
        XCTAssertTrue(forward.changes.contains {
            $0.kind == .ownershipChanged && $0.before?.contains("kind=binding") == true && $0.after?.contains("kind=state") == true
        })
        XCTAssertTrue(forward.changes.contains { $0.kind == .bindingRemoved })
        XCTAssertFalse(forward.changes.contains { [.nodeAdded, .nodeRemoved].contains($0.kind) && ($0.nodes.contains(binding.id) || $0.nodes.contains(state.id)) })
        XCTAssertTrue(reverse.changes.contains {
            $0.kind == .ownershipChanged && $0.before?.contains("kind=state") == true && $0.after?.contains("kind=binding") == true
        })
        XCTAssertTrue(reverse.changes.contains { $0.kind == .bindingAdded })
        XCTAssertFalse(reverse.changes.contains { [.nodeAdded, .nodeRemoved].contains($0.kind) && ($0.nodes.contains(binding.id) || $0.nodes.contains(state.id)) })
    }

    func testContinuityIsQualifiedAndDoesNotHideRenameOrOverloadChanges() {
        let owner = node("M.Editor", .view)
        let nestedOwner = node("M.Nested", .view)
        let original = node("M.Editor.value", .binding)
        let renamed = node("M.Editor.renamed", .state)
        let nestedBinding = node("M.Nested.value", .binding)
        let nestedState = node("M.Nested.value", .state)
        let overloadA = node("M.Editor.apply", .function, discriminator: "String")
        let overloadB = node("M.Editor.apply", .function, discriminator: "Int")
        let base = snapshot(
            graph: SemanticGraph(nodes: [owner, nestedOwner, original, nestedBinding, overloadA], edges: []),
            values: [value(original), value(nestedBinding)], findings: [], duplicated: 0
        )
        let current = snapshot(
            graph: SemanticGraph(nodes: [owner, nestedOwner, renamed, nestedState, overloadB], edges: []),
            values: [value(renamed), value(nestedState)], findings: [], duplicated: 0
        )
        let report = SemanticDiffEngine().compare(base: base, current: current)

        XCTAssertTrue(report.changes.contains { $0.kind == .nodeRemoved && $0.nodes == [original.id] })
        XCTAssertTrue(report.changes.contains { $0.kind == .nodeAdded && $0.nodes == [renamed.id] })
        XCTAssertFalse(report.changes.contains { [.nodeAdded, .nodeRemoved].contains($0.kind) && ($0.nodes.contains(nestedBinding.id) || $0.nodes.contains(nestedState.id)) })
        XCTAssertTrue(report.changes.contains { $0.kind == .nodeRemoved && $0.nodes == [overloadA.id] })
        XCTAssertTrue(report.changes.contains { $0.kind == .nodeAdded && $0.nodes == [overloadB.id] })
    }

    func testGitRevisionLoaderMatchesSnapshotDiffAndDoesNotMutateRepository() throws {
        let temporary = makeTemporaryDirectory(prefix: "swiftui-audit-git-diff")
        defer { try? FileManager.default.removeItem(at: temporary) }
        let repository = temporary.appendingPathComponent("Repository", isDirectory: true)
        try FileManager.default.createDirectory(at: repository.appendingPathComponent("Sources"), withIntermediateDirectories: true)
        let runner = BoundedProcessRunner()
        try runGit(runner, ["init", "-q"], repository)
        try runGit(runner, ["config", "user.email", "tests@example.invalid"], repository)
        try runGit(runner, ["config", "user.name", "Tests"], repository)
        let source = repository.appendingPathComponent("Sources/With Space.swift")
        try Self.mirroredSource.write(to: source, atomically: true, encoding: .utf8)
        try Data([0x00, 0xFF, 0x10]).write(to: repository.appendingPathComponent("asset.bin"))
        try runGit(runner, ["add", "."], repository)
        try runGit(runner, ["commit", "-qm", "before"], repository)
        try Self.bindingSource.write(to: source, atomically: true, encoding: .utf8)
        let executable = repository.appendingPathComponent("Sources/Executable:Tool.swift")
        try "struct ExecutableTool {}\n".write(to: executable, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executable.path)
        let newlineSource = repository.appendingPathComponent("Sources/Line\nBreak.swift")
        try "struct NewlinePath {}\n".write(to: newlineSource, atomically: true, encoding: .utf8)
        try FileManager.default.createSymbolicLink(
            atPath: repository.appendingPathComponent("Sources/Valid.swift").path,
            withDestinationPath: "With Space.swift"
        )
        try FileManager.default.createSymbolicLink(
            atPath: repository.appendingPathComponent("Sources/Dangling.swift").path,
            withDestinationPath: "Missing.swift"
        )
        try runGit(runner, ["add", "."], repository)
        try runGit(runner, ["commit", "-qm", "after"], repository)

        let branchBefore = try gitOutput(runner, ["branch", "--show-current"], repository)
        let statusBefore = try gitOutput(runner, ["status", "--porcelain=v1"], repository)
        let loader = SemanticInputLoader(timeout: 5)
        let base = try loader.loadRevision("HEAD~1", repositoryURL: repository)
        let current = try loader.loadRevision("HEAD", repositoryURL: repository)
        let live = try loader.loadLive(sourceURL: repository)
        XCTAssertEqual(current.snapshot.graph, live.snapshot.graph)
        XCTAssertEqual(current.snapshot.report, live.snapshot.report)
        XCTAssertTrue(current.snapshot.graph.nodes.contains { $0.qualifiedName.contains("ExecutableTool") })
        XCTAssertTrue(current.snapshot.graph.nodes.contains { $0.qualifiedName.contains("NewlinePath") })
        XCTAssertFalse(current.snapshot.graph.nodes.contains { $0.evidence.contains { $0.file.hasSuffix("Valid.swift") || $0.file.hasSuffix("Dangling.swift") } })
        let gitDiff = SemanticDiffEngine().compare(
            base: base.snapshot,
            current: current.snapshot,
            baseIdentity: base.identity,
            currentIdentity: current.identity
        )

        let baseDirectory = temporary.appendingPathComponent("base-snapshot")
        let currentDirectory = temporary.appendingPathComponent("current-snapshot")
        try SnapshotWriter().write(
            graph: base.snapshot.graph,
            report: base.snapshot.report,
            manifest: base.snapshot.manifest,
            sourceURL: repository,
            to: baseDirectory
        )
        try SnapshotWriter().write(
            graph: current.snapshot.graph,
            report: current.snapshot.report,
            manifest: current.snapshot.manifest,
            sourceURL: repository,
            to: currentDirectory
        )
        let snapshotDiff = SemanticDiffEngine().compare(
            base: try SnapshotReader().read(from: baseDirectory),
            current: try SnapshotReader().read(from: currentDirectory),
            baseIdentity: base.identity,
            currentIdentity: current.identity
        )
        XCTAssertEqual(gitDiff, snapshotDiff)
        XCTAssertEqual(try SnapshotReader().read(from: currentDirectory), current.snapshot)
        XCTAssertEqual(try gitOutput(runner, ["branch", "--show-current"], repository), branchBefore)
        XCTAssertEqual(try gitOutput(runner, ["status", "--porcelain=v1"], repository), statusBefore)
        XCTAssertThrowsError(try loader.loadRevision("missing-revision", repositoryURL: repository)) {
            XCTAssertEqual($0 as? SemanticInputError, .invalidRevision("missing-revision"))
        }
    }

    func testBoundedProcessRunnerTimesOut() {
        XCTAssertThrowsError(try BoundedProcessRunner().run(
            "sh", arguments: ["-c", "sleep 2"], timeout: 0.05
        )) {
            guard case BoundedProcessError.timeout = $0 else { return XCTFail("unexpected error: \($0)") }
        }
    }

    private func syntheticPair() -> (base: SemanticSnapshot, current: SemanticSnapshot) {
        let module = node("M", .module)
        let ownerA = node("M.OwnerA", .type)
        let ownerB = node("M.OwnerB", .type)
        let value = node("M.value", .state)
        let mirror = node("M.mirror", .property)
        let inputA = node("M.inputA", .property)
        let inputB = node("M.inputB", .property)
        let removed = node("M.removed", .property)
        let added = node("M.added", .property)
        let baseOwn = edge(.owns, ownerA, value, "base-own")
        let currentOwn = edge(.owns, ownerB, value, "current-own")
        let baseRead = edge(.reads, ownerA, value, "base-read")
        let currentRead = edge(.reads, ownerB, value, "current-read")
        let baseWrite = edge(.writes, ownerA, mirror, "base-write")
        let currentWrite = edge(.writes, ownerB, value, "current-write")
        let baseBind = edge(.binds, ownerA, value, "base-bind")
        let currentBind = edge(.binds, ownerB, value, "current-bind")
        let baseDerive = edge(.derivesFrom, value, inputA, "base-derive")
        let currentDerive = edge(.derivesFrom, value, inputB, "current-derive")
        let baseManual = AuditFinding(
            rule: .manualTwoWaySync,
            severity: .high,
            confidence: .strongInference,
            nodes: [value.id, mirror.id],
            edges: [baseWrite.id],
            evidence: baseWrite.evidence,
            suggestedPatterns: ["Binding"]
        )
        let currentManual = AuditFinding(
            rule: .manualTwoWaySync,
            severity: .high,
            confidence: .strongInference,
            nodes: [value.id, mirror.id],
            edges: [currentWrite.id],
            evidence: currentWrite.evidence,
            suggestedPatterns: ["Binding"]
        )
        let baseGraph = SemanticGraph(
            nodes: [module, ownerA, ownerB, value, mirror, inputA, inputB, removed],
            edges: [baseOwn, baseRead, baseWrite, baseBind, baseDerive]
        )
        let currentGraph = SemanticGraph(
            nodes: [module, ownerA, ownerB, value, mirror, inputA, inputB, added],
            edges: [currentOwn, currentRead, currentWrite, currentBind, currentDerive]
        )
        let semanticID = "value:common"
        let baseValue = NormalizedSemanticValue(
            id: semanticID,
            representations: [value.id, mirror.id],
            relationEdges: [baseWrite.id],
            confidence: .deterministic,
            classification: nil,
            evidence: baseWrite.evidence
        )
        let currentValue = NormalizedSemanticValue(
            id: semanticID,
            representations: [value.id],
            relationEdges: [],
            confidence: .deterministic,
            classification: nil,
            evidence: value.evidence
        )
        return (
            snapshot(graph: baseGraph, values: [baseValue], findings: [baseManual], duplicated: 1),
            snapshot(graph: currentGraph, values: [currentValue], findings: [currentManual], duplicated: 0)
        )
    }

    private func node(_ qualifiedName: String, _ kind: NodeKind, discriminator: String = "declaration") -> SemanticNode {
        SemanticNode(
            id: StableID.node(module: "M", qualifiedName: qualifiedName, kind: kind, discriminator: discriminator),
            kind: kind,
            name: qualifiedName.split(separator: ".").last.map(String.init) ?? qualifiedName,
            qualifiedName: qualifiedName,
            evidence: [Evidence(file: "Fixture.swift", startLine: 1, endLine: 1, kind: "test")]
        )
    }

    private func value(_ node: SemanticNode) -> NormalizedSemanticValue {
        NormalizedSemanticValue(
            id: StableID.semanticValue(representations: [node.id]),
            representations: [node.id], relationEdges: [], confidence: .deterministic,
            classification: nil, evidence: node.evidence
        )
    }

    private func boundaryNode(_ qualifiedName: String, _ kind: NodeKind) -> SemanticNode {
        SemanticNode(
            id: StableID.node(module: "M", qualifiedName: qualifiedName, kind: kind, discriminator: "declaration"),
            kind: kind,
            name: qualifiedName.split(separator: ".").last.map(String.init) ?? qualifiedName,
            qualifiedName: qualifiedName,
            evidence: [Evidence(file: "Fixture.swift", startLine: 1, endLine: 1, kind: "property-wrapper")]
        )
    }

    private func assertSourceCount(
        _ report: SemanticDiffReport,
        before: Int,
        after: Int,
        beforeRepresentations: Int,
        afterRepresentations: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let changes = report.changes.filter { $0.kind == .sourceOfTruthCountChanged }
        XCTAssertEqual(changes.count, 1, file: file, line: line)
        XCTAssertEqual(changes.first?.before, "representations=\(beforeRepresentations);sources=\(before)", file: file, line: line)
        XCTAssertEqual(changes.first?.after, "representations=\(afterRepresentations);sources=\(after)", file: file, line: line)
        let delta = report.affectedSemanticValues.first { $0.beforeSourceCount == (beforeRepresentations == 0 ? nil : before) && $0.afterSourceCount == after }
        XCTAssertEqual(delta?.beforeRepresentationCount ?? 0, beforeRepresentations, file: file, line: line)
        XCTAssertEqual(delta?.afterRepresentationCount ?? 0, afterRepresentations, file: file, line: line)
    }

    private func edge(_ kind: EdgeKind, _ from: SemanticNode, _ to: SemanticNode, _ discriminator: String) -> SemanticEdge {
        SemanticEdge(
            id: StableID.edge(kind: kind, from: from.id, to: to.id, discriminator: discriminator),
            kind: kind,
            from: from.id,
            to: to.id,
            evidence: [Evidence(file: "Fixture.swift", startLine: 1, endLine: 1, kind: discriminator)],
            confidence: .deterministic
        )
    }

    private func snapshot(
        graph: SemanticGraph,
        values: [NormalizedSemanticValue],
        findings: [AuditFinding],
        duplicated: Int
    ) -> SemanticSnapshot {
        let metrics = AuditMetrics(
            mutableSemanticValues: values.count,
            stateRepresentations: graph.nodes.filter { $0.kind == .state }.count,
            bindingEdges: graph.edges.filter { $0.kind == .binds }.count,
            manualSynchronizationEdges: findings.filter { $0.rule == .manualTwoWaySync }.count,
            callbackTunnels: 0,
            derivedMutableValues: graph.edges.contains { $0.kind == .derivesFrom } ? 1 : 0,
            duplicatedSourcesOfTruth: duplicated,
            ownershipViolations: 0
        )
        let report = AuditReport(resolution: graph.resolution, metrics: metrics, semanticValues: values, findings: findings)
        let manifest = SnapshotManifest(
            swiftVersion: "test",
            repositoryRevision: "test-revision",
            generatedFrom: "."
        )
        return SemanticSnapshot(manifest: manifest, graph: graph, report: report)
    }

    private func scanSource(_ source: String, container: String) throws -> SemanticSnapshot {
        let temporary = makeTemporaryDirectory(prefix: "swiftui-audit-diff-\(container)")
        defer { try? FileManager.default.removeItem(at: temporary) }
        let root = temporary.appendingPathComponent("Scenario", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try source.write(to: root.appendingPathComponent("Fixture.swift"), atomically: true, encoding: .utf8)
        let graph = try GraphScanner().scan(path: root.path)
        let report = AuditEngine().audit(graph: graph)
        return SemanticSnapshot(
            manifest: SnapshotManifest(swiftVersion: "test", repositoryRevision: container, generatedFrom: "."),
            graph: graph,
            report: report
        )
    }

    private func makeTemporaryDirectory(prefix: String) -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(prefix)-\(UUID().uuidString)")
        try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func runGit(_ runner: BoundedProcessRunner, _ arguments: [String], _ repository: URL) throws {
        _ = try runner.runChecked("git", arguments: arguments, currentDirectory: repository, timeout: 5)
    }

    private func gitOutput(_ runner: BoundedProcessRunner, _ arguments: [String], _ repository: URL) throws -> String {
        try runner.runChecked("git", arguments: arguments, currentDirectory: repository, timeout: 5)
            .outputString.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static let mirroredSource = """
    import SwiftUI
    struct Editor: View {
        var value: String
        @State private var localValue: String = ""
        var body: some View {
            TextField("Value", text: $localValue)
                .onChange(of: value) { localValue = value }
                .onChange(of: localValue) { value = localValue }
        }
    }
    """

    private static let bindingSource = """
    import SwiftUI
    struct Editor: View {
        @Binding var value: String
        var body: some View { TextField("Value", text: $value) }
    }
    """
}
