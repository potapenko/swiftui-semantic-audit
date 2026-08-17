import ArgumentParser
import Foundation
import SemanticDiff

struct Doctor: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Inspect Swift, Xcode, package, index, and Git prerequisites without mutation."
    )

    enum OutputFormat: String, ExpressibleByArgument {
        case json
    }

    @Argument(help: "Project directory to inspect.")
    var path: String = "."

    @Option(name: .long, help: "Emit deterministic JSON.")
    var format: OutputFormat?

    mutating func run() throws {
        let doctor = EnvironmentDoctor()
        let report = doctor.inspect(path: URL(fileURLWithPath: path, isDirectory: true))
        if format == .json {
            FileHandle.standardOutput.write(try report.jsonData())
        } else {
            FileHandle.standardOutput.write(Data(doctor.humanDescription(report).utf8))
        }
        if report.overallStatus == .error { throw ExitCode.failure }
    }
}
