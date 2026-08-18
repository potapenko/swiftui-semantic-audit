import AuditCore
import Foundation

public enum IndexSelection: Equatable, Sendable {
    case syntaxOnly
    case automatic
    case explicit(URL)
}

public struct IndexEnrichmentRequest: Codable, Sendable {
    public let sourceRoot: String
    public let indexStorePath: String
    public let databasePath: String
    public let indexStoreLibraryPath: String
    public let graph: SemanticGraph

    public init(
        sourceRoot: String,
        indexStorePath: String,
        databasePath: String,
        indexStoreLibraryPath: String,
        graph: SemanticGraph
    ) {
        self.sourceRoot = sourceRoot
        self.indexStorePath = indexStorePath
        self.databasePath = databasePath
        self.indexStoreLibraryPath = indexStoreLibraryPath
        self.graph = graph
    }
}

public struct IndexEnrichmentResponse: Codable, Sendable {
    public let graph: SemanticGraph
    public let mappedSymbols: Int
    public let indexedFacts: Int

    public init(graph: SemanticGraph, mappedSymbols: Int, indexedFacts: Int) {
        self.graph = graph
        self.mappedSymbols = mappedSymbols
        self.indexedFacts = indexedFacts
    }
}

public protocol SymbolResolver: Sendable {
    func enrich(_ request: IndexEnrichmentRequest) throws -> IndexEnrichmentResponse
}

public enum IndexStoreBackend {
    public static var isAvailable: Bool {
        #if canImport(IndexStoreDB) && os(macOS)
        true
        #else
        false
        #endif
    }
}
