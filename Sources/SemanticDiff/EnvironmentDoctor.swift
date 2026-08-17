import AuditCore
import Foundation

public enum DoctorStatus: String, Codable, Sendable {
    case ok
    case warning
    case error
}

public struct DoctorCheck: Codable, Equatable, Sendable {
    public let status: DoctorStatus
    public let detail: String

    public init(status: DoctorStatus, detail: String) {
        self.status = status
        self.detail = detail
    }
}

public struct DoctorReport: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let overallStatus: DoctorStatus
    public let swift: DoctorCheck
    public let xcode: DoctorCheck
    public let toolchain: DoctorCheck
    public let projectType: DoctorCheck
    public let swiftSyntax: DoctorCheck
    public let indexStore: DoctorCheck
    public let git: DoctorCheck

    public init(
        swift: DoctorCheck,
        xcode: DoctorCheck,
        toolchain: DoctorCheck,
        projectType: DoctorCheck,
        swiftSyntax: DoctorCheck,
        indexStore: DoctorCheck,
        git: DoctorCheck
    ) {
        self.schemaVersion = 1
        self.swift = swift
        self.xcode = xcode
        self.toolchain = toolchain
        self.projectType = projectType
        self.swiftSyntax = swiftSyntax
        self.indexStore = indexStore
        self.git = git
        let statuses = [swift.status, xcode.status, toolchain.status, projectType.status, swiftSyntax.status, indexStore.status, git.status]
        self.overallStatus = statuses.contains(.error) ? .error : (statuses.contains(.warning) ? .warning : .ok)
    }

    public func jsonData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        var data = try encoder.encode(self)
        data.append(0x0A)
        return data
    }
}

public struct EnvironmentDoctor: Sendable {
    private let runner: any ProcessRunning
    private let timeout: TimeInterval

    public init(runner: any ProcessRunning = BoundedProcessRunner(), timeout: TimeInterval = 5) {
        self.runner = runner
        self.timeout = timeout
    }

    public func inspect(path: URL) -> DoctorReport {
        let root = path.standardizedFileURL.resolvingSymlinksInPath()
        let swiftResult = validatedSwift()
        let swift = swiftResult.check
        let xcode = validatedXcode()
        let toolchain = validatedToolchain()
        let projectType = projectCheck(root)
        let swiftSyntax = swiftSyntaxCheck(root, swiftVersion: swiftResult.version)
        let indexStore = indexStoreCheck(root)
        let gitCommand = validatedGit()
        let git: DoctorCheck
        if gitCommand.status == .ok {
            let repository = probe("git", arguments: ["-C", root.path, "rev-parse", "--is-inside-work-tree"])
            git = repository.result?.status == 0 && repository.result?.outputString.trimmingCharacters(in: .whitespacesAndNewlines) == "true"
                ? DoctorCheck(status: .ok, detail: gitCommand.detail)
                : DoctorCheck(status: .warning, detail: "git available; input is not inside a work tree")
        } else {
            git = gitCommand
        }
        return DoctorReport(
            swift: swift,
            xcode: xcode,
            toolchain: toolchain,
            projectType: projectType,
            swiftSyntax: swiftSyntax,
            indexStore: indexStore,
            git: git
        )
    }

    public func humanDescription(_ report: DoctorReport) -> String {
        let checks: [(String, DoctorCheck)] = [
            ("Swift", report.swift),
            ("Xcode", report.xcode),
            ("Toolchain", report.toolchain),
            ("Project type", report.projectType),
            ("SwiftSyntax", report.swiftSyntax),
            ("Index Store", report.indexStore),
            ("Git", report.git),
        ]
        var lines = ["Doctor: \(report.overallStatus.rawValue)"]
        for (name, check) in checks {
            lines.append("\(name): \(check.status.rawValue) — \(check.detail)")
        }
        return lines.joined(separator: "\n") + "\n"
    }

    private func probe(_ command: String, arguments: [String]) -> ProcessProbe {
        do {
            let result = try runner.run(command, arguments: arguments, currentDirectory: nil, timeout: timeout)
            return ProcessProbe(result: result, error: nil)
        } catch {
            return ProcessProbe(result: nil, error: error.localizedDescription)
        }
    }

    private func validatedSwift() -> (check: DoctorCheck, version: SemanticVersion?) {
        let probe = probe("swift", arguments: ["--version"])
        guard let result = probe.result else {
            return (DoctorCheck(status: .error, detail: probe.error ?? "unavailable"), nil)
        }
        guard result.status == 0 else { return (failedCheck(result, required: true), nil) }
        let output = normalized(result.outputString)
        guard output.contains("Swift version"), let version = SemanticVersion.first(in: output) else {
            return (DoctorCheck(status: .error, detail: "unrecognized Swift version output"), nil)
        }
        return (DoctorCheck(status: .ok, detail: "Swift \(version)"), version)
    }

    private func validatedXcode() -> DoctorCheck {
        let probe = probe("xcodebuild", arguments: ["-version"])
        guard let result = probe.result else {
            return DoctorCheck(status: .warning, detail: probe.error ?? "unavailable")
        }
        guard result.status == 0 else { return failedCheck(result, required: false) }
        let lines = result.outputString.split(whereSeparator: \.isNewline).map(String.init)
        guard let versionLine = lines.first, versionLine.hasPrefix("Xcode "),
              let version = MajorMinorVersion.first(in: versionLine),
              let buildLine = lines.dropFirst().first, buildLine.hasPrefix("Build version "),
              buildLine.dropFirst("Build version ".count).contains(where: { $0.isNumber || $0.isLetter })
        else { return DoctorCheck(status: .warning, detail: "unrecognized Xcode version output") }
        return DoctorCheck(status: .ok, detail: "Xcode \(version); \(buildLine)")
    }

    private func validatedToolchain() -> DoctorCheck {
        let probe = probe("xcrun", arguments: ["--find", "swift"])
        guard let result = probe.result else {
            return DoctorCheck(status: .warning, detail: probe.error ?? "unavailable")
        }
        guard result.status == 0 else { return failedCheck(result, required: false) }
        let path = result.outputString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard path.hasPrefix("/"), FileManager.default.fileExists(atPath: path) else {
            return DoctorCheck(status: .warning, detail: "xcrun returned a missing or non-absolute Swift path")
        }
        return DoctorCheck(status: .ok, detail: path)
    }

    private func validatedGit() -> DoctorCheck {
        let probe = probe("git", arguments: ["--version"])
        guard let result = probe.result else {
            return DoctorCheck(status: .error, detail: probe.error ?? "unavailable")
        }
        guard result.status == 0 else { return failedCheck(result, required: true) }
        let output = normalized(result.outputString)
        guard output.hasPrefix("git version "), let version = SemanticVersion.first(in: output) else {
            return DoctorCheck(status: .error, detail: "unrecognized Git version output")
        }
        return DoctorCheck(status: .ok, detail: "git \(version)")
    }

    private func failedCheck(_ result: BoundedProcessResult, required: Bool) -> DoctorCheck {
        let detail = normalized(result.errorString)
        return DoctorCheck(
            status: required ? .error : .warning,
            detail: detail.isEmpty ? "unavailable (status \(result.status))" : detail
        )
    }

    private func normalized(_ value: String) -> String {
        value.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    private func projectCheck(_ root: URL) -> DoctorCheck {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: root.appendingPathComponent("Package.swift").path) {
            return DoctorCheck(status: .ok, detail: "swift-package")
        }
        if let entries = try? fileManager.contentsOfDirectory(atPath: root.path),
           entries.contains(where: { $0.hasSuffix(".xcodeproj") || $0.hasSuffix(".xcworkspace") }) {
            return DoctorCheck(status: .ok, detail: "xcode-project")
        }
        return DoctorCheck(status: .warning, detail: "source-directory")
    }

    private func swiftSyntaxCheck(_ root: URL, swiftVersion: SemanticVersion?) -> DoctorCheck {
        let resolved = root.appendingPathComponent("Package.resolved")
        var version: String?
        if let data = try? Data(contentsOf: resolved),
           let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let pins = object["pins"] as? [[String: Any]] {
            for pin in pins where pin["identity"] as? String == "swift-syntax" {
                version = (pin["state"] as? [String: Any])?["version"] as? String
            }
        }
        if version == nil,
           let package = try? String(contentsOf: root.appendingPathComponent("Package.swift"), encoding: .utf8),
           let dependencyRange = package.range(of: "swift-syntax") {
            version = SemanticVersion.first(in: String(package[dependencyRange.lowerBound...])).map(String.init)
        }
        guard let version else { return DoctorCheck(status: .warning, detail: "dependency version not found") }
        guard let dependency = SemanticVersion(exact: version) else {
            return DoctorCheck(status: .error, detail: "malformed SwiftSyntax dependency version: \(version)")
        }
        guard let swiftVersion else {
            return DoctorCheck(status: .error, detail: "SwiftSyntax \(dependency) compatibility unknown because Swift version is invalid")
        }
        let expectedTrain = swiftVersion.major * 100 + swiftVersion.minor
        guard dependency.major == expectedTrain else {
            return DoctorCheck(
                status: .error,
                detail: "SwiftSyntax \(dependency) release train \(dependency.major) requires Swift \(dependency.major / 100).\(dependency.major % 100), but toolchain is Swift \(swiftVersion.major).\(swiftVersion.minor)"
            )
        }
        return DoctorCheck(
            status: .ok,
            detail: "SwiftSyntax \(dependency) release train \(dependency.major) matches Swift \(swiftVersion.major).\(swiftVersion.minor)"
        )
    }

    private func indexStoreCheck(_ root: URL) -> DoctorCheck {
        let build = root.appendingPathComponent(".build", isDirectory: true)
        guard let enumerator = FileManager.default.enumerator(
            at: build,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: []
        ) else { return DoctorCheck(status: .warning, detail: "not found (optional in syntax-only mode)") }
        for case let url as URL in enumerator where url.path.hasSuffix("/index/store") {
            return DoctorCheck(status: .ok, detail: "available under .build")
        }
        return DoctorCheck(status: .warning, detail: "not found (optional in syntax-only mode)")
    }
}

private struct ProcessProbe {
    let result: BoundedProcessResult?
    let error: String?
}

private struct SemanticVersion: CustomStringConvertible, Equatable {
    let major: Int
    let minor: Int
    let patch: Int

    init?(exact value: String) {
        let parts = value.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3,
              let major = Int(parts[0]), let minor = Int(parts[1]), let patch = Int(parts[2])
        else { return nil }
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    static func first(in value: String) -> SemanticVersion? {
        let pattern = #"(?<![0-9])([0-9]+)\.([0-9]+)\.([0-9]+)(?![0-9])"#
        guard let expression = try? NSRegularExpression(pattern: pattern),
              let match = expression.firstMatch(in: value, range: NSRange(value.startIndex..., in: value)),
              let range = Range(match.range, in: value)
        else { return nil }
        return SemanticVersion(exact: String(value[range]))
    }

    var description: String { "\(major).\(minor).\(patch)" }
}

private struct MajorMinorVersion: CustomStringConvertible {
    let major: Int
    let minor: Int

    static func first(in value: String) -> MajorMinorVersion? {
        let pattern = #"(?<![0-9])([0-9]+)\.([0-9]+)(?![0-9])"#
        guard let expression = try? NSRegularExpression(pattern: pattern),
              let match = expression.firstMatch(in: value, range: NSRange(value.startIndex..., in: value)),
              match.numberOfRanges == 3,
              let majorRange = Range(match.range(at: 1), in: value),
              let minorRange = Range(match.range(at: 2), in: value),
              let major = Int(value[majorRange]), let minor = Int(value[minorRange])
        else { return nil }
        return MajorMinorVersion(major: major, minor: minor)
    }

    var description: String { "\(major).\(minor)" }
}
