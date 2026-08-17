import Darwin
import Foundation

public struct BoundedProcessResult: Equatable, Sendable {
    public let status: Int32
    public let standardOutput: Data
    public let standardError: Data

    public init(status: Int32, standardOutput: Data, standardError: Data) {
        self.status = status
        self.standardOutput = standardOutput
        self.standardError = standardError
    }

    public var outputString: String {
        String(decoding: standardOutput, as: UTF8.self)
    }

    public var errorString: String {
        String(decoding: standardError, as: UTF8.self)
    }
}

public enum BoundedProcessError: Error, Equatable, LocalizedError {
    case invalidTimeout(Double)
    case launch(String, String)
    case timeout(String, Double)
    case failed(String, Int32, String)

    public var errorDescription: String? {
        switch self {
        case .invalidTimeout(let timeout):
            "process timeout must be positive, received \(timeout)"
        case .launch(let command, let detail):
            "could not launch \(command): \(detail)"
        case .timeout(let command, let timeout):
            "process timed out after \(timeout) seconds: \(command)"
        case .failed(let command, let status, let detail):
            "process failed with status \(status): \(command)\(detail.isEmpty ? "" : ": \(detail)")"
        }
    }
}

public protocol ProcessRunning: Sendable {
    func run(
        _ command: String,
        arguments: [String],
        currentDirectory: URL?,
        timeout: TimeInterval
    ) throws -> BoundedProcessResult
}

public struct BoundedProcessRunner: ProcessRunning, Sendable {
    public init() {}

    public func run(
        _ command: String,
        arguments: [String] = [],
        currentDirectory: URL? = nil,
        timeout: TimeInterval
    ) throws -> BoundedProcessResult {
        guard timeout > 0 else { throw BoundedProcessError.invalidTimeout(timeout) }
        let fileManager = FileManager.default
        let container = fileManager.temporaryDirectory
            .appendingPathComponent("swiftui-audit-process-\(UUID().uuidString)", isDirectory: true)
        let stdoutURL = container.appendingPathComponent("stdout")
        let stderrURL = container.appendingPathComponent("stderr")
        try fileManager.createDirectory(at: container, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: container) }
        fileManager.createFile(atPath: stdoutURL.path, contents: Data())
        fileManager.createFile(atPath: stderrURL.path, contents: Data())
        let stdout = try FileHandle(forWritingTo: stdoutURL)
        let stderr = try FileHandle(forWritingTo: stderrURL)
        defer {
            try? stdout.close()
            try? stderr.close()
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [command] + arguments
        process.currentDirectoryURL = currentDirectory
        process.standardOutput = stdout
        process.standardError = stderr
        let completion = DispatchSemaphore(value: 0)
        process.terminationHandler = { _ in completion.signal() }
        do {
            try process.run()
        } catch {
            throw BoundedProcessError.launch(command, error.localizedDescription)
        }
        if completion.wait(timeout: .now() + timeout) == .timedOut {
            process.terminate()
            if completion.wait(timeout: .now() + 1) == .timedOut {
                kill(process.processIdentifier, SIGKILL)
                _ = completion.wait(timeout: .now() + 1)
            }
            throw BoundedProcessError.timeout(([command] + arguments).joined(separator: " "), timeout)
        }
        try stdout.synchronize()
        try stderr.synchronize()
        return BoundedProcessResult(
            status: process.terminationStatus,
            standardOutput: try Data(contentsOf: stdoutURL),
            standardError: try Data(contentsOf: stderrURL)
        )
    }

    public func runChecked(
        _ command: String,
        arguments: [String] = [],
        currentDirectory: URL? = nil,
        timeout: TimeInterval
    ) throws -> BoundedProcessResult {
        let result = try run(command, arguments: arguments, currentDirectory: currentDirectory, timeout: timeout)
        guard result.status == 0 else {
            throw BoundedProcessError.failed(
                ([command] + arguments).joined(separator: " "),
                result.status,
                result.errorString.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }
        return result
    }
}
