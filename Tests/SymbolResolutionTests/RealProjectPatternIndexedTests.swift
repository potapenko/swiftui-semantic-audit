import AuditCore
import AuditRules
import Foundation
import SemanticDiff
import SymbolResolution
import SwiftSyntaxFrontend
import XCTest

final class RealProjectPatternIndexedTests: XCTestCase {
    func testRealProjectPatternFindingsSurviveFreshIndexedEnrichmentWithoutDuplication() throws {
        let temporary = FileManager.default.temporaryDirectory
            .appendingPathComponent("swiftui-audit-real-pattern-index-\(UUID().uuidString)", isDirectory: true)
        let store = temporary.appendingPathComponent("index/store", isDirectory: true)
        let output = temporary.appendingPathComponent("output", isDirectory: true)
        try FileManager.default.createDirectory(at: store, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporary) }
        try buildIndex(store: store, output: output)

        let configuration = try XCTUnwrap(AnalysisConfiguration.load(
            explicitURL: fixtureRoot.appendingPathComponent(".swiftui-audit.json"),
            sourceURL: fixtureRoot
        ))
        let syntaxGraph = configuration.applying(to: try GraphScanner().scan(path: fixtureRoot.path))
        let syntaxReport = AuditEngine().audit(graph: syntaxGraph)
        let first = try enrich(syntaxGraph, store: store, database: temporary.appendingPathComponent("db-a"))
        let second = try enrich(syntaxGraph, store: store, database: temporary.appendingPathComponent("db-b"))
        let firstReport = AuditEngine().audit(graph: first)
        let secondReport = AuditEngine().audit(graph: second)

        XCTAssertEqual(first.resolution, "indexed")
        XCTAssertEqual(first.configurationDigest, configuration.digest)
        XCTAssertEqual(try first.jsonData(), try second.jsonData())
        XCTAssertEqual(try firstReport.jsonData(), try secondReport.jsonData())
        XCTAssertEqual(findingMatrix(firstReport), findingMatrix(syntaxReport))
        XCTAssertEqual(firstReport.findings.count, 34)
        XCTAssertTrue(firstReport.findings.allSatisfy { finding in
            finding.evidence.allSatisfy { !$0.file.hasPrefix("Good/") }
        })
    }

    private func findingMatrix(_ report: AuditReport) -> [String: Int] {
        var result: [String: Int] = [:]
        for finding in report.findings {
            let files = Set(finding.evidence.map(\.file)).sorted().joined(separator: ",")
            result["\(finding.rule.rawValue)|\(files)", default: 0] += 1
        }
        return result
    }

    private func buildIndex(store: URL, output: URL) throws {
        let sources = try FileManager.default.subpathsOfDirectory(atPath: fixtureRoot.path)
            .filter { $0.hasSuffix(".swift") }
            .sorted()
            .map { fixtureRoot.appendingPathComponent($0).path }
        _ = try BoundedProcessRunner().runChecked(
            "/usr/bin/xcrun",
            arguments: [
                "swiftc",
                "-module-name", "RealProjectPatterns",
                "-index-store-path", store.path,
                "-parse-as-library",
                "-emit-module",
            ] + sources + ["-o", output.appendingPathComponent("RealProjectPatterns.swiftmodule").path],
            timeout: 60
        )
    }

    private func enrich(_ graph: SemanticGraph, store: URL, database: URL) throws -> SemanticGraph {
        try IndexStoreDBResolver().enrich(IndexEnrichmentRequest(
            sourceRoot: fixtureRoot.path,
            indexStorePath: store.path,
            databasePath: database.path,
            indexStoreLibraryPath: indexStoreLibrary.path,
            graph: graph
        )).graph
    }

    private var indexStoreLibrary: URL {
        let result = try! BoundedProcessRunner().runChecked(
            "/usr/bin/xcrun", arguments: ["--find", "swiftc"], timeout: 5
        )
        let swiftc = URL(fileURLWithPath: result.outputString.trimmingCharacters(in: .whitespacesAndNewlines))
            .standardizedFileURL.resolvingSymlinksInPath()
        return swiftc.deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("lib/libIndexStore.dylib")
    }

    private var fixtureRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures/RealProjectPatterns", isDirectory: true)
    }
}
