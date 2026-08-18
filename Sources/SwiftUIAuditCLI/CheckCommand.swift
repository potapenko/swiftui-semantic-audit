import ArgumentParser
import AuditCore
import Foundation
import SemanticDiff

struct Check: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Fail only when current source introduces findings at or above a severity threshold."
    )

    enum OutputFormat: String, ExpressibleByArgument {
        case json
    }

    enum SeverityArgument: String, ExpressibleByArgument {
        case low
        case medium
        case high

        var severity: Severity {
            switch self {
            case .low: .low
            case .medium: .medium
            case .high: .high
            }
        }
    }

    @Option(name: .long, help: "Baseline snapshot directory or Git revision.")
    var baseline: String

    @Argument(help: "Current live Swift source path.")
    var path: String = "."

    @Option(name: .long, help: "Git repository used for a revision baseline.")
    var repository: String = "."

    @Option(name: .long, help: "Minimum severity that fails on a new finding.")
    var failOnNew: SeverityArgument = .high

    @Option(name: .long, help: "Emit deterministic JSON.")
    var format: OutputFormat?

    @OptionGroup var resolution: ResolutionOptions

    mutating func run() throws {
        let loader = SemanticInputLoader()
        let baselineInput = try loader.loadOperand(
            baseline,
            repositoryURL: URL(fileURLWithPath: repository, isDirectory: true)
        )
        let currentInput = try loader.loadComparableLive(
            sourceURL: URL(fileURLWithPath: path),
            baseline: baselineInput,
            requestedSelection: try resolution.selection(),
            configurationURL: resolution.configurationURL(),
            helperExecutable: try currentExecutableURL()
        )
        let diff = SemanticDiffEngine().compare(
            base: baselineInput.snapshot,
            current: currentInput.snapshot,
            baseIdentity: baselineInput.identity,
            currentIdentity: currentInput.identity
        )
        let policy = CheckPolicy()
        let report = policy.evaluate(diff: diff, failOnNew: failOnNew.severity)
        if format == .json {
            FileHandle.standardOutput.write(try report.jsonData())
        } else {
            FileHandle.standardOutput.write(Data(policy.humanDescription(report).utf8))
        }
        if !report.passed { throw ExitCode(2) }
    }
}
