import AuditCore
import Darwin
import Foundation
import ProjectWorkspace

public struct ProjectServiceResult: Codable, Equatable, Sendable {
    public let projectID: String
    public let label: String
    public let running: Bool
    public let changed: Bool

    public func jsonData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        var data = try encoder.encode(self)
        data.append(0x0A)
        return data
    }
}

public struct ProjectServiceController: Sendable {
    private let runner: any ProcessRunning
    private let timeout: TimeInterval

    public init(runner: any ProcessRunning = BoundedProcessRunner(), timeout: TimeInterval = 15) {
        self.runner = runner
        self.timeout = timeout
    }

    public func start(
        projectRoot: URL,
        executable: URL,
        applicationSupportRoot: URL? = nil
    ) throws -> ProjectServiceResult {
        let locations = ProjectRuntimeLocations(
            projectRoot: projectRoot, applicationSupportRoot: applicationSupportRoot
        )
        let label = serviceLabel(locations.projectID)
        if isRunning(label: label) {
            return ProjectServiceResult(projectID: locations.projectID, label: label, running: true, changed: false)
        }
        try FileManager.default.createDirectory(at: locations.root, withIntermediateDirectories: true)
        let plist: [String: Any] = [
            "Label": label,
            "ProgramArguments": [executable.path, "project", "watch", projectRoot.path],
            "WorkingDirectory": projectRoot.path,
            "RunAtLoad": true,
            "KeepAlive": false,
            "StandardOutPath": locations.stdoutLog.path,
            "StandardErrorPath": locations.stderrLog.path,
            "ProcessType": "Background",
        ]
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try data.write(to: locations.servicePlist, options: .atomic)
        let result = try runner.run(
            "/bin/launchctl",
            arguments: ["bootstrap", domain, locations.servicePlist.path],
            currentDirectory: nil,
            timeout: timeout
        )
        guard result.status == 0 else {
            throw BoundedProcessError.failed(
                "launchctl bootstrap \(label)", result.status,
                result.errorString.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }
        return ProjectServiceResult(projectID: locations.projectID, label: label, running: true, changed: true)
    }

    public func stop(
        projectRoot: URL,
        applicationSupportRoot: URL? = nil
    ) throws -> ProjectServiceResult {
        let locations = ProjectRuntimeLocations(
            projectRoot: projectRoot, applicationSupportRoot: applicationSupportRoot
        )
        let label = serviceLabel(locations.projectID)
        guard isRunning(label: label) else {
            return ProjectServiceResult(projectID: locations.projectID, label: label, running: false, changed: false)
        }
        let result = try runner.run(
            "/bin/launchctl",
            arguments: ["bootout", "\(domain)/\(label)"],
            currentDirectory: nil,
            timeout: timeout
        )
        guard result.status == 0 else {
            throw BoundedProcessError.failed(
                "launchctl bootout \(label)", result.status,
                result.errorString.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }
        return ProjectServiceResult(projectID: locations.projectID, label: label, running: false, changed: true)
    }

    public func isRunning(
        projectRoot: URL,
        applicationSupportRoot: URL? = nil
    ) -> Bool {
        let locations = ProjectRuntimeLocations(
            projectRoot: projectRoot, applicationSupportRoot: applicationSupportRoot
        )
        return isRunning(label: serviceLabel(locations.projectID))
    }

    private var domain: String { "gui/\(getuid())" }

    private func serviceLabel(_ projectID: String) -> String {
        "dev.swiftui-audit.project.\(projectID)"
    }

    private func isRunning(label: String) -> Bool {
        guard let result = try? runner.run(
            "/bin/launchctl",
            arguments: ["print", "\(domain)/\(label)"],
            currentDirectory: nil,
            timeout: timeout
        ) else { return false }
        return result.status == 0
    }
}
