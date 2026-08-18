import ArgumentParser
import Foundation
import SymbolResolution

struct IndexEnrichHelper: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "_index-enrich",
        shouldDisplay: false
    )

    @Option(name: .long, help: .hidden)
    var request: String

    @Option(name: .long, help: .hidden)
    var response: String

    mutating func run() throws {
        let requestURL = URL(fileURLWithPath: request)
        let responseURL = URL(fileURLWithPath: response)
        let payload = try JSONDecoder().decode(
            IndexEnrichmentRequest.self,
            from: Data(contentsOf: requestURL)
        )
        let result = try IndexStoreDBResolver().enrich(payload)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        try encoder.encode(result).write(to: responseURL, options: .atomic)
    }
}
