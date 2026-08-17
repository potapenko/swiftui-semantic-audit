import AuditCore
import Foundation
import SemanticDiff
import XCTest

final class EnvironmentDoctorTests: XCTestCase {
    func testActualEnvironmentJSONAndHumanOutput() throws {
        let report = EnvironmentDoctor().inspect(path: projectRoot)
        let data = try report.jsonData()

        XCTAssertNoThrow(try JSONSerialization.jsonObject(with: data))
        XCTAssertEqual(report.swift.status, .ok)
        XCTAssertEqual(report.projectType.detail, "swift-package")
        XCTAssertEqual(report.swiftSyntax.status, .ok)
        XCTAssertTrue(report.swiftSyntax.detail.contains("603.0.2"))
        XCTAssertEqual(report.git.status, .ok)
        let human = EnvironmentDoctor().humanDescription(report)
        for field in ["Swift:", "Xcode:", "Toolchain:", "Project type:", "SwiftSyntax:", "Index Store:", "Git:"] {
            XCTAssertTrue(human.contains(field))
        }
    }

    func testMissingAndTimeoutProcessesAreReportedWithoutMutation() {
        let report = EnvironmentDoctor(runner: MockRunner(), timeout: 0.1).inspect(path: projectRoot)

        XCTAssertEqual(report.swift.status, .error)
        XCTAssertTrue(report.swift.detail.contains("timed out"))
        XCTAssertEqual(report.xcode.status, .warning)
        XCTAssertEqual(report.git.status, .error)
        XCTAssertEqual(report.overallStatus, .error)
    }

    func testStructuredOutputsAndReleaseTrainCompatibility() throws {
        let compatibleRoot = try packageRoot(swiftSyntaxVersion: "603.0.2")
        defer { try? FileManager.default.removeItem(at: compatibleRoot) }
        let compatible = EnvironmentDoctor(runner: StructuredRunner(), timeout: 0.1).inspect(path: compatibleRoot)
        XCTAssertEqual(compatible.swift.status, .ok)
        XCTAssertEqual(compatible.xcode.status, .ok)
        XCTAssertEqual(compatible.toolchain.status, .ok)
        XCTAssertEqual(compatible.git.status, .ok)
        XCTAssertEqual(compatible.swiftSyntax.status, .ok)
        XCTAssertTrue(compatible.swiftSyntax.detail.contains("release train 603 matches Swift 6.3"))

        let mismatchRoot = try packageRoot(swiftSyntaxVersion: "602.0.0")
        defer { try? FileManager.default.removeItem(at: mismatchRoot) }
        let mismatch = EnvironmentDoctor(runner: StructuredRunner(), timeout: 0.1).inspect(path: mismatchRoot)
        XCTAssertEqual(mismatch.swiftSyntax.status, .error)
        XCTAssertTrue(mismatch.swiftSyntax.detail.contains("requires Swift 6.2"))
        XCTAssertTrue(mismatch.swiftSyntax.detail.contains("toolchain is Swift 6.3"))

        let malformedRoot = try packageRoot(swiftSyntaxVersion: "not-semver")
        defer { try? FileManager.default.removeItem(at: malformedRoot) }
        let malformed = EnvironmentDoctor(runner: StructuredRunner(), timeout: 0.1).inspect(path: malformedRoot)
        XCTAssertEqual(malformed.swiftSyntax.status, .error)
        XCTAssertTrue(malformed.swiftSyntax.detail.contains("malformed"))
    }

    func testEmptySuccessfulCommandOutputsAreNeverReportedOK() throws {
        let root = try packageRoot(swiftSyntaxVersion: "603.0.2")
        defer { try? FileManager.default.removeItem(at: root) }
        let report = EnvironmentDoctor(runner: EmptySuccessRunner(), timeout: 0.1).inspect(path: root)

        XCTAssertEqual(report.swift.status, .error)
        XCTAssertEqual(report.xcode.status, .warning)
        XCTAssertEqual(report.toolchain.status, .warning)
        XCTAssertEqual(report.git.status, .error)
        XCTAssertEqual(report.swiftSyntax.status, .error)
    }

    func testOddSuccessfulCommandOutputsAreNeverReportedOK() throws {
        let root = try packageRoot(swiftSyntaxVersion: "603.0.2")
        defer { try? FileManager.default.removeItem(at: root) }
        let report = EnvironmentDoctor(runner: OddSuccessRunner(), timeout: 0.1).inspect(path: root)

        XCTAssertEqual(report.swift.status, .error)
        XCTAssertEqual(report.xcode.status, .warning)
        XCTAssertEqual(report.toolchain.status, .warning)
        XCTAssertEqual(report.git.status, .error)
        XCTAssertEqual(report.swiftSyntax.status, .error)
    }

    private var projectRoot: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    }

    private func packageRoot(swiftSyntaxVersion: String) throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("swiftui-audit-doctor-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try "// swift-tools-version: 6.2\n".write(
            to: root.appendingPathComponent("Package.swift"), atomically: true, encoding: .utf8
        )
        let resolved: [String: Any] = [
            "pins": [[
                "identity": "swift-syntax",
                "state": ["version": swiftSyntaxVersion],
            ]],
        ]
        try JSONSerialization.data(withJSONObject: resolved, options: [.sortedKeys])
            .write(to: root.appendingPathComponent("Package.resolved"), options: .atomic)
        return root
    }
}

private struct MockRunner: ProcessRunning {
    func run(
        _ command: String,
        arguments: [String],
        currentDirectory: URL?,
        timeout: TimeInterval
    ) throws -> BoundedProcessResult {
        if command == "swift" { throw BoundedProcessError.timeout("swift --version", timeout) }
        if command == "git" { return BoundedProcessResult(status: 127, standardOutput: Data(), standardError: Data("missing".utf8)) }
        return BoundedProcessResult(status: 127, standardOutput: Data(), standardError: Data("optional missing".utf8))
    }
}

private struct StructuredRunner: ProcessRunning {
    func run(
        _ command: String,
        arguments: [String],
        currentDirectory: URL?,
        timeout: TimeInterval
    ) throws -> BoundedProcessResult {
        let output: String
        switch (command, arguments) {
        case ("swift", ["--version"]):
            output = "Apple Swift version 6.3.3 (swiftlang-test)\nTarget: arm64-apple-macosx\n"
        case ("xcodebuild", ["-version"]):
            output = "Xcode 26.6\nBuild version 17F113\n"
        case ("xcrun", ["--find", "swift"]):
            output = "/usr/bin/swift\n"
        case ("git", ["--version"]):
            output = "git version 2.50.1\n"
        case ("git", _):
            output = "true\n"
        default:
            return BoundedProcessResult(status: 127, standardOutput: Data(), standardError: Data("unexpected".utf8))
        }
        return BoundedProcessResult(status: 0, standardOutput: Data(output.utf8), standardError: Data())
    }
}

private struct EmptySuccessRunner: ProcessRunning {
    func run(
        _ command: String,
        arguments: [String],
        currentDirectory: URL?,
        timeout: TimeInterval
    ) throws -> BoundedProcessResult {
        BoundedProcessResult(status: 0, standardOutput: Data(), standardError: Data())
    }
}

private struct OddSuccessRunner: ProcessRunning {
    func run(
        _ command: String,
        arguments: [String],
        currentDirectory: URL?,
        timeout: TimeInterval
    ) throws -> BoundedProcessResult {
        let output: String
        switch command {
        case "swift": output = "Swift banana\n"
        case "xcodebuild": output = "Xcode banana\nBuild version\n"
        case "xcrun": output = "relative/swift\n"
        case "git": output = "git version banana\n"
        default: output = "odd\n"
        }
        return BoundedProcessResult(status: 0, standardOutput: Data(output.utf8), standardError: Data())
    }
}
