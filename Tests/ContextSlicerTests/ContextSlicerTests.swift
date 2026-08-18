import AuditCore
import AuditRules
import ContextSlicer
import Foundation
import SnapshotStore
import SwiftSyntaxFrontend
import XCTest

final class ContextSlicerTests: XCTestCase {
    func testEveryMandatoryFindingProducesDeterministicStrictValidSlice() throws {
        let (graph, report) = try mixedAudit()
        let stateFlowRules = Array(RuleID.allCases.prefix(10))
        XCTAssertEqual(Set(report.findings.map(\.rule)), Set(stateFlowRules))

        for rule in stateFlowRules {
            let finding = try XCTUnwrap(report.findings.first { $0.rule == rule })
            let first = try ContextSlicer().slice(graph: graph, report: report, findingID: finding.id)
            let second = try ContextSlicer().slice(graph: graph, report: report, findingID: finding.id)

            XCTAssertEqual(try first.jsonData(), try second.jsonData(), "non-deterministic \(rule)")
            XCTAssertLessThan(first.nodes.count, graph.nodes.count, "non-minimal node set for \(rule)")
            XCTAssertLessThan(first.edges.count, graph.edges.count, "non-minimal edge set for \(rule)")
            XCTAssertFalse(first.sourceEvidence.isEmpty)
            XCTAssertTrue(first.sourceEvidence.allSatisfy { !$0.file.hasPrefix("/") })
            try assertValidReferences(first)
        }
    }

    func testSymbolLookupSupportsExactNameIDAndRejectsAmbiguousOrUnknown() throws {
        let (graph, report) = try mixedAudit()
        let node = try XCTUnwrap(graph.nodes.first { $0.qualifiedName == "RuleTests.DirectBindingField.name" })
        let exact = try ContextSlicer().slice(graph: graph, report: report, symbol: node.qualifiedName)
        let stableID = try ContextSlicer().slice(graph: graph, report: report, symbol: node.id)

        XCTAssertEqual(exact.metadata.selection, "symbol:\(node.id)")
        XCTAssertEqual(exact.nodes, stableID.nodes)
        try assertValidReferences(exact)

        XCTAssertThrowsError(try ContextSlicer().slice(graph: graph, report: report, symbol: "body")) {
            guard case ContextSliceError.ambiguousSymbol("body", let candidates) = $0 else {
                return XCTFail("unexpected error: \($0)")
            }
            XCTAssertGreaterThan(candidates.count, 1)
            XCTAssertEqual(candidates, candidates.sorted())
        }
        XCTAssertThrowsError(try ContextSlicer().slice(graph: graph, report: report, symbol: "Missing.value")) {
            XCTAssertEqual($0 as? ContextSliceError, .unknownSymbol("Missing.value"))
        }
    }

    func testBudgetMateriallyReducesSliceAndPreservesMandatoryEnvelope() throws {
        let (graph, report) = try mixedAudit()
        let finding = try XCTUnwrap(report.findings.first { $0.rule == .callbackBindingTunnel })
        let slicer = ContextSlicer()
        let full = try slicer.slice(graph: graph, report: report, findingID: finding.id)
        var reduced: ContextSlice?

        for budget in stride(from: full.metadata.estimatedTokens - 1, through: 100, by: -100) {
            if let candidate = try? slicer.slice(
                graph: graph,
                report: report,
                findingID: finding.id,
                tokenBudget: budget
            ), candidate.metadata.truncated {
                reduced = candidate
                break
            }
        }
        let budgeted = try XCTUnwrap(reduced, "no enforceable budget between full and mandatory slices")
        let repeated = try slicer.slice(
            graph: graph,
            report: report,
            findingID: finding.id,
            tokenBudget: try XCTUnwrap(budgeted.metadata.tokenBudget)
        )

        XCTAssertLessThan(try budgeted.jsonData().count, try full.jsonData().count)
        XCTAssertLessThanOrEqual(budgeted.metadata.estimatedTokens, budgeted.metadata.tokenBudget!)
        XCTAssertEqual(budgeted.finding?.id, finding.id)
        XCTAssertFalse(budgeted.questions.isEmpty)
        XCTAssertEqual(try budgeted.jsonData(), try repeated.jsonData())
        try assertValidReferences(budgeted)

        XCTAssertThrowsError(try slicer.slice(
            graph: graph,
            report: report,
            findingID: finding.id,
            tokenBudget: 1
        )) {
            guard case ContextSliceError.insufficientBudget(requested: 1, minimum: let minimum) = $0 else {
                return XCTFail("unexpected error: \($0)")
            }
            XCTAssertGreaterThan(minimum, 1)
            let minimumResult = Result { try slicer.slice(
                graph: graph,
                report: report,
                findingID: finding.id,
                tokenBudget: minimum
            ) }
            if case .failure(let error) = minimumResult { XCTFail("reported minimum failed: \(error)") }
            let belowResult = Result { try slicer.slice(
                graph: graph,
                report: report,
                findingID: finding.id,
                tokenBudget: minimum - 1
            ) }
            switch belowResult {
            case .failure(let boundaryError):
                XCTAssertEqual(
                    boundaryError as? ContextSliceError,
                    .insufficientBudget(requested: minimum - 1, minimum: minimum)
                )
            case .success:
                XCTFail("budget below reported minimum unexpectedly succeeded")
            }
        }

        for boundary in [9, 10, 99, 100, 999, 1_000] {
            XCTAssertThrowsError(try slicer.slice(
                graph: graph,
                report: report,
                findingID: finding.id,
                tokenBudget: boundary
            )) { error in
                guard case ContextSliceError.insufficientBudget(requested: boundary, minimum: let minimum) = error else {
                    return XCTFail("unexpected error at boundary \(boundary): \(error)")
                }
                let minimumResult = Result { try slicer.slice(
                    graph: graph,
                    report: report,
                    findingID: finding.id,
                    tokenBudget: minimum
                ) }
                if case .failure(let minimumError) = minimumResult {
                    XCTFail("reported minimum failed at boundary \(boundary): \(minimumError)")
                }
            }
        }
    }

    func testInputClassificationPrefersFullSnapshotTreatsStrayManifestAsSourceAndRejectsPartial() throws {
        let temporary = FileManager.default.temporaryDirectory
            .appendingPathComponent("swiftui-audit-input-tests-\(UUID().uuidString)")
        let semantic = temporary.appendingPathComponent(".semantic")
        try FileManager.default.createDirectory(at: temporary, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporary) }
        let graph = try GraphScanner().scan(path: fixtureRoot.path)
        let report = AuditEngine().audit(graph: graph)
        let manifest = SnapshotManifestFactory.make(sourcePath: fixtureRoot.path)
        try SnapshotWriter().write(
            graph: graph,
            report: report,
            manifest: manifest,
            sourceURL: fixtureRoot,
            to: semantic
        )

        XCTAssertEqual(
            try SliceInputResolver().resolve(input: nil, currentDirectory: temporary),
            .snapshot(semantic.standardizedFileURL)
        )

        let source = temporary.appendingPathComponent("Source", isDirectory: true)
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        try Data("struct SourceValue {}\n".utf8).write(to: source.appendingPathComponent("Fixture.swift"))
        try Data("{\"unrelated\":true}\n".utf8).write(to: source.appendingPathComponent("manifest.json"))
        XCTAssertEqual(
            try SliceInputResolver().resolve(input: source.path, currentDirectory: temporary),
            .source(source.standardizedFileURL)
        )

        let partial = temporary.appendingPathComponent("Partial", isDirectory: true)
        try FileManager.default.createDirectory(at: partial, withIntermediateDirectories: true)
        try Data("{}\n".utf8).write(to: partial.appendingPathComponent("manifest.json"))
        XCTAssertThrowsError(try SliceInputResolver().resolve(input: partial.path, currentDirectory: temporary)) {
            guard case SnapshotError.incompleteSnapshot(let missing) = $0 else {
                return XCTFail("unexpected error: \($0)")
            }
            XCTAssertEqual(missing, ["edges.jsonl", "findings.jsonl", "nodes.jsonl", "summary.json"])
        }
    }

    func testHumanSliceIncludesRequiredHeadings() throws {
        let (graph, report) = try mixedAudit()
        let finding = try XCTUnwrap(report.findings.first)
        let slice = try ContextSlicer().slice(graph: graph, report: report, findingID: finding.id)
        let human = ContextSlicer().humanDescription(slice)

        for heading in ["OWNER", "READ PATH", "WRITE PATH", "FINDING", "SOURCE EVIDENCE"] {
            XCTAssertTrue(human.contains(heading))
        }
    }

    private func mixedAudit() throws -> (SemanticGraph, AuditReport) {
        let graph = try GraphScanner().scan(path: fixtureRoot.path)
        return (graph, AuditEngine().audit(graph: graph))
    }

    private var fixtureRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures/RuleTests", isDirectory: true)
    }

    private func assertValidReferences(_ slice: ContextSlice) throws {
        let nodeIDs = Set(slice.nodes.map(\.id))
        let edgeIDs = Set(slice.edges.map(\.id))
        XCTAssertTrue(slice.edges.allSatisfy { nodeIDs.contains($0.from) && nodeIDs.contains($0.to) })
        if let finding = slice.finding {
            XCTAssertTrue(finding.nodes.allSatisfy(nodeIDs.contains))
            XCTAssertTrue(finding.edges.allSatisfy(edgeIDs.contains))
        }
        for value in slice.semanticValues {
            XCTAssertTrue(value.representations.allSatisfy(nodeIDs.contains))
            XCTAssertTrue(value.relationEdges.allSatisfy(edgeIDs.contains))
        }
    }
}
