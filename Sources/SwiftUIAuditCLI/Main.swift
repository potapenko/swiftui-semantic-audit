import ArgumentParser
import AuditCore
import AuditRules
import ContextSlicer
import Foundation
import SemanticDiff
import SnapshotStore
import SymbolResolution
import SwiftSyntaxFrontend

@main
struct SwiftUIAudit: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "swiftui-audit",
        abstract: "Build a deterministic semantic graph from Swift/SwiftUI source.",
        subcommands: [Scan.self, Audit.self, Snapshot.self, Slice.self, Diff.self, Check.self, Doctor.self, IndexEnrichHelper.self]
    )
}

struct Snapshot: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Persist a deterministic semantic graph and audit sidecar."
    )

    enum OutputFormat: String, ExpressibleByArgument {
        case json
    }

    @Argument(help: "A Swift file or directory to snapshot.")
    var path: String = "."

    @Option(name: .long, help: "Snapshot sidecar directory.")
    var output: String = ".semantic"

    @Option(name: .long, help: "Emit a deterministic machine-readable summary.")
    var format: OutputFormat?

    @OptionGroup var resolution: ResolutionOptions

    mutating func run() throws {
        let locations = try SnapshotPathPolicy.validate(
            sourceURL: URL(fileURLWithPath: path),
            outputURL: URL(fileURLWithPath: output)
        )
        if let cacheDirectory = resolution.cacheDirectory {
            let cache = URL(fileURLWithPath: cacheDirectory, isDirectory: true)
                .standardizedFileURL.resolvingSymlinksInPath()
            let outputPrefix = locations.output.path.hasSuffix("/")
                ? locations.output.path : locations.output.path + "/"
            if cache == locations.output || cache.path.hasPrefix(outputPrefix) {
                throw ValidationError("--cache-directory must be outside the five-file snapshot output")
            }
        }
        let graph = try loadResolvedGraph(path: locations.source.path, options: resolution)
        let report = AuditEngine().audit(graph: graph)
        let manifest = SnapshotManifestFactory.make(
            sourcePath: locations.source.path,
            toolVersion: report.toolVersion,
            configurationDigest: graph.configurationDigest
        )
        try SnapshotWriter().write(
            graph: graph,
            report: report,
            manifest: manifest,
            sourceURL: locations.source,
            to: locations.output
        )
        if format == .json {
            let response = SnapshotResponse(
                manifest: manifest,
                summary: SnapshotSummary(graph: graph, report: report)
            )
            FileHandle.standardOutput.write(try canonicalJSON(response))
        } else {
            print("Snapshot written: \(output) (\(graph.nodes.count) nodes, \(graph.edges.count) edges, \(report.findings.count) findings)")
        }
    }
}

struct Slice: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Render a bounded semantic subgraph for one finding or symbol."
    )

    enum OutputFormat: String, ExpressibleByArgument {
        case llmJSON = "llm-json"
    }

    @Argument(help: "An explicit snapshot directory or source path. Defaults to .semantic, then live source.")
    var input: String?

    @Option(name: .long, help: "Exact finding ID.")
    var finding: String?

    @Option(name: .long, help: "Exact stable ID, qualified name, or unambiguous suffix.")
    var symbol: String?

    @Option(name: .long, help: "Output format.")
    var format: OutputFormat?

    @Option(name: .long, help: "Conservative maximum estimated token count.")
    var tokenBudget: Int?

    @OptionGroup var resolution: ResolutionOptions

    mutating func validate() throws {
        guard (finding == nil) != (symbol == nil) else {
            throw ValidationError("provide exactly one of --finding or --symbol")
        }
        if let tokenBudget, tokenBudget <= 0 {
            throw ValidationError("--token-budget must be positive")
        }
    }

    mutating func run() throws {
        let currentDirectory = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
        let resolved = try SliceInputResolver().resolve(input: input, currentDirectory: currentDirectory)
        let graph: SemanticGraph
        let report: AuditReport
        switch resolved {
        case .snapshot(let url):
            if resolution.indexStore != nil || resolution.config != nil || resolution.cacheDirectory != nil || resolution.noCache {
                throw ValidationError("index, config, and cache options apply only when slicing live source")
            }
            let snapshot = try SnapshotReader().read(from: url)
            graph = snapshot.graph
            report = snapshot.report
        case .source(let url):
            graph = try loadResolvedGraph(path: url.path, options: resolution)
            report = AuditEngine().audit(graph: graph)
        }

        let slicer = ContextSlicer()
        let result: ContextSlice
        if let finding {
            result = try slicer.slice(
                graph: graph,
                report: report,
                findingID: finding,
                tokenBudget: tokenBudget
            )
        } else {
            result = try slicer.slice(
                graph: graph,
                report: report,
                symbol: symbol!,
                tokenBudget: tokenBudget
            )
        }
        if format == .llmJSON {
            FileHandle.standardOutput.write(try result.jsonData())
        } else {
            FileHandle.standardOutput.write(Data(slicer.humanDescription(result).utf8))
        }
    }
}

struct Audit: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Evaluate the SwiftUI state/data-flow and architecture rules."
    )

    enum OutputFormat: String, ExpressibleByArgument {
        case json
    }

    @Argument(help: "A Swift file or directory to audit.")
    var path: String

    @Option(name: .long, help: "Emit deterministic machine-readable output.")
    var format: OutputFormat?

    @OptionGroup var resolution: ResolutionOptions

    mutating func run() throws {
        let graph = try loadResolvedGraph(path: path, options: resolution)
        let report = AuditEngine().audit(graph: graph)
        if format == .json {
            FileHandle.standardOutput.write(try report.jsonData())
        } else {
            let counts = Dictionary(grouping: report.findings, by: \.rule).mapValues(\.count)
            print("\(report.findings.count) findings")
            for rule in RuleID.allCases {
                if let count = counts[rule], count > 0 {
                    print("\(rule.rawValue): \(count)")
                }
            }
        }
    }
}

struct Scan: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Parse Swift source and emit a semantic graph."
    )

    enum OutputFormat: String, ExpressibleByArgument {
        case json
    }

    @Argument(help: "A Swift file or directory to scan.")
    var path: String

    @Option(name: .long, help: "Output format.")
    var format: OutputFormat = .json

    @Option(name: .long, help: "Write JSON to this explicit file path.")
    var output: String?

    @OptionGroup var resolution: ResolutionOptions

    mutating func run() throws {
        let graph = try loadResolvedGraph(path: path, options: resolution)
        let data = try graph.jsonData()
        if let output {
            try data.write(to: URL(fileURLWithPath: output), options: .atomic)
        } else {
            FileHandle.standardOutput.write(data)
        }
    }
}

private struct SnapshotResponse: Codable {
    let manifest: SnapshotManifest
    let summary: SnapshotSummary
}

private func canonicalJSON<T: Encodable>(_ value: T) throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    var data = try encoder.encode(value)
    data.append(0x0A)
    return data
}
