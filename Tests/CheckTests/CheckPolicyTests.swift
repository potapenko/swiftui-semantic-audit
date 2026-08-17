import AuditCore
import AuditRules
import Foundation
import SemanticDiff
import SnapshotStore
import SwiftSyntaxFrontend
import XCTest

final class CheckPolicyTests: XCTestCase {
    func testNewHighFailsButLegacyBaselineAlonePasses() throws {
        let clean = try scan(Self.bindingSource)
        let violating = try scan(Self.mirroredSource)
        let engine = SemanticDiffEngine()
        let introduced = engine.compare(base: clean, current: violating)
        let legacy = engine.compare(base: violating, current: violating)

        XCTAssertFalse(CheckPolicy().evaluate(diff: introduced, failOnNew: .high).passed)
        XCTAssertTrue(CheckPolicy().evaluate(diff: legacy, failOnNew: .high).passed)
        XCTAssertTrue(introduced.newFindings.contains { $0.severity == .high })
    }

    func testSeverityThresholdOrdering() throws {
        let clean = try scan(Self.bindingSource)
        let derived = try scan(Self.derivedSource)
        let diff = SemanticDiffEngine().compare(base: clean, current: derived)

        XCTAssertTrue(CheckPolicy().evaluate(diff: diff, failOnNew: .high).passed)
        XCTAssertFalse(CheckPolicy().evaluate(diff: diff, failOnNew: .medium).passed)
        XCTAssertFalse(CheckPolicy().evaluate(diff: diff, failOnNew: .low).passed)
    }

    func testLeadingLineShiftDoesNotCreateNewFinding() throws {
        let base = try scan(Self.mirroredSource)
        let shifted = try scan("\n\n\n" + Self.mirroredSource)
        let diff = SemanticDiffEngine().compare(base: base, current: shifted)

        XCTAssertTrue(diff.newFindings.isEmpty)
        XCTAssertTrue(diff.resolvedFindings.isEmpty)
        XCTAssertTrue(CheckPolicy().evaluate(diff: diff, failOnNew: .high).passed)
    }

    func testRevisionBaselineAgainstWorkingSourceFailsWithoutMutatingGitState() throws {
        let container = FileManager.default.temporaryDirectory
            .appendingPathComponent("swiftui-audit-check-revision-\(UUID().uuidString)")
        let repository = container.appendingPathComponent("Scenario", isDirectory: true)
        try FileManager.default.createDirectory(at: repository, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: container) }
        let runner = BoundedProcessRunner()
        try runGit(runner, ["init", "-q"], repository)
        try runGit(runner, ["config", "user.email", "tests@example.invalid"], repository)
        try runGit(runner, ["config", "user.name", "Tests"], repository)
        let source = repository.appendingPathComponent("Fixture.swift")
        try Self.bindingSource.write(to: source, atomically: true, encoding: .utf8)
        try runGit(runner, ["add", "Fixture.swift"], repository)
        try runGit(runner, ["commit", "-qm", "baseline"], repository)
        try Self.mirroredSource.write(to: source, atomically: true, encoding: .utf8)
        let branchBefore = try gitOutput(runner, ["branch", "--show-current"], repository)
        let statusBefore = try gitOutput(runner, ["status", "--porcelain=v1"], repository)

        let loader = SemanticInputLoader(timeout: 5)
        let baseline = try loader.loadRevision("HEAD", repositoryURL: repository)
        let current = try loader.loadLive(sourceURL: repository)
        let diff = SemanticDiffEngine().compare(
            base: baseline.snapshot,
            current: current.snapshot,
            baseIdentity: baseline.identity,
            currentIdentity: current.identity
        )

        XCTAssertFalse(CheckPolicy().evaluate(diff: diff, failOnNew: .high).passed)
        XCTAssertTrue(diff.newFindings.contains { $0.severity == .high })
        XCTAssertEqual(try gitOutput(runner, ["branch", "--show-current"], repository), branchBefore)
        XCTAssertEqual(try gitOutput(runner, ["status", "--porcelain=v1"], repository), statusBefore)
    }

    private func scan(_ source: String) throws -> SemanticSnapshot {
        let container = FileManager.default.temporaryDirectory
            .appendingPathComponent("swiftui-audit-check-\(UUID().uuidString)")
        let root = container.appendingPathComponent("Scenario", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: container) }
        try source.write(to: root.appendingPathComponent("Fixture.swift"), atomically: true, encoding: .utf8)
        let graph = try GraphScanner().scan(path: root.path)
        let report = AuditEngine().audit(graph: graph)
        return SemanticSnapshot(
            manifest: SnapshotManifest(swiftVersion: "test", repositoryRevision: "test", generatedFrom: "."),
            graph: graph,
            report: report
        )
    }

    private func runGit(_ runner: BoundedProcessRunner, _ arguments: [String], _ repository: URL) throws {
        _ = try runner.runChecked("git", arguments: arguments, currentDirectory: repository, timeout: 5)
    }

    private func gitOutput(_ runner: BoundedProcessRunner, _ arguments: [String], _ repository: URL) throws -> String {
        try runner.runChecked("git", arguments: arguments, currentDirectory: repository, timeout: 5)
            .outputString.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static let bindingSource = """
    import SwiftUI
    struct Editor: View {
        @Binding var value: String
        var body: some View { TextField("Value", text: $value) }
    }
    """

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

    private static let derivedSource = """
    import SwiftUI
    struct Editor: View {
        let input: String
        @State private var canSubmit = false
        var body: some View { Text(input).onAppear { canSubmit = !input.isEmpty } }
    }
    """
}
