import ArgumentParser
import Foundation
import SemanticDiff

struct Diff: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Compare two semantic snapshots or Git revisions."
    )

    enum OutputFormat: String, ExpressibleByArgument {
        case json
    }

    @Argument(help: "Base snapshot directory or Git revision.")
    var base: String

    @Argument(help: "Current snapshot directory or Git revision.")
    var current: String

    @Option(name: .long, help: "Git repository used for revision operands.")
    var repository: String = "."

    @Option(name: .long, help: "Emit deterministic JSON.")
    var format: OutputFormat?

    mutating func run() throws {
        let loader = SemanticInputLoader()
        let repositoryURL = URL(fileURLWithPath: repository, isDirectory: true)
        let baseInput = try loader.loadOperand(base, repositoryURL: repositoryURL)
        let currentInput = try loader.loadOperand(current, repositoryURL: repositoryURL)
        try loader.validateMatchingResolution(base: baseInput, current: currentInput)
        let engine = SemanticDiffEngine()
        let report = engine.compare(
            base: baseInput.snapshot,
            current: currentInput.snapshot,
            baseIdentity: baseInput.identity,
            currentIdentity: currentInput.identity
        )
        if format == .json {
            FileHandle.standardOutput.write(try report.jsonData())
        } else {
            FileHandle.standardOutput.write(Data(engine.humanDescription(report).utf8))
        }
    }
}
