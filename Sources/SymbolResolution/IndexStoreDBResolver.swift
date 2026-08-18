import AuditCore
import Foundation

#if canImport(IndexStoreDB) && os(macOS)
import IndexStoreDB

public struct IndexStoreDBResolver: SymbolResolver, Sendable {
    public init() {}

    public func enrich(_ request: IndexEnrichmentRequest) throws -> IndexEnrichmentResponse {
        let sourceRoot = URL(fileURLWithPath: request.sourceRoot).standardizedFileURL.resolvingSymlinksInPath()
        let files = swiftFiles(at: sourceRoot)
        guard !files.isEmpty else { throw IndexResolutionError.noProjectCoverage(request.indexStorePath) }
        let library = try IndexStoreLibrary(dylibPath: request.indexStoreLibraryPath)
        let database = try IndexStoreDB(
            storePath: request.indexStorePath,
            databasePath: request.databasePath,
            library: library,
            waitUntilDoneInitializing: true
        )
        let coveredFiles = files.filter { !database.unitNamesContainingFile(path: $0.path).isEmpty }
        guard !coveredFiles.isEmpty else {
            throw IndexResolutionError.noProjectCoverage(request.indexStorePath)
        }
        var knownPaths: [String: String] = [:]
        for file in coveredFiles {
            knownPaths[file.standardizedFileURL.resolvingSymlinksInPath().path] = relativePath(
                for: file, root: sourceRoot
            )
        }
        let sourceLines = sourceLinesByRelativePath(knownPaths: knownPaths)
        let occurrences = coveredFiles.flatMap { database.symbolOccurrences(inFilePath: $0.path) }
            .compactMap { IndexedOccurrence($0, knownPaths: knownPaths) }
            .sorted(by: IndexedOccurrence.canonicalOrder)
        guard !occurrences.isEmpty else {
            throw IndexResolutionError.noProjectCoverage(request.indexStorePath)
        }
        return enrich(graph: request.graph, occurrences: occurrences, sourceLines: sourceLines)
    }

    private func enrich(
        graph: SemanticGraph,
        occurrences: [IndexedOccurrence],
        sourceLines: [String: [Substring]]
    ) -> IndexEnrichmentResponse {
        let definitions = occurrences.filter { $0.roles.contains(.definition) || $0.roles.contains(.declaration) }
        let declarationsByLocation = Dictionary(grouping: definitions) { "\($0.file)|\($0.line)" }
        let references = occurrences.filter {
            $0.roles.contains(.reference) || $0.roles.contains(.read) ||
                $0.roles.contains(.write) || $0.roles.contains(.call)
        }
        let referencesByLocation = Dictionary(grouping: references) { "\($0.file)|\($0.line)" }
        var syntaxUSR: [String: String] = [:]
        var declarationByUSR: [String: SemanticNode] = [:]
        for node in graph.nodes.sorted(by: { $0.id < $1.id }) {
            let candidates = Array(Set(node.evidence.flatMap { evidence -> [IndexedOccurrence] in
                let key = "\(evidence.file)|\(evidence.startLine)"
                return declarationsByLocation[key] ?? []
            })).filter { occurrence in
                namesMatch(node.name, occurrence.name) && kindsCompatible(node.kind, occurrence.kind)
            }
            let usrs = Set(candidates.map(\.usr))
            guard usrs.count == 1, let usr = usrs.first else { continue }
            syntaxUSR[node.id] = usr
            if let existing = declarationByUSR[usr] {
                declarationByUSR[usr] = preferred(existing, node)
            } else {
                declarationByUSR[usr] = node
            }
        }
        for node in graph.nodes.sorted(by: { $0.id < $1.id }) where syntaxUSR[node.id] == nil {
            guard isCompilerResolvableUseSite(node) else { continue }
            let candidates = Array(Set(node.evidence.flatMap { evidence -> [IndexedOccurrence] in
                let key = "\(evidence.file)|\(evidence.startLine)"
                return referencesByLocation[key] ?? []
            })).filter { occurrence in
                namesMatch(node.name, occurrence.name) &&
                    occurrenceStartsAtLeaf(occurrence, sourceLines: sourceLines)
            }
            let usrs = Set(candidates.map(\.usr))
            guard usrs.count == 1, let usr = usrs.first else { continue }
            syntaxUSR[node.id] = usr
        }

        var nodesByID: [String: SemanticNode] = [:]
        for node in graph.nodes.sorted(by: { $0.id < $1.id }) {
            guard let usr = syntaxUSR[node.id] else {
                nodesByID[node.id] = node
                continue
            }
            let id = StableID.compilerSymbol(usr: usr)
            let compilerEvidence = occurrences.filter { $0.usr == usr }.map(\.evidence)
            let canonical = declarationByUSR[usr] ?? node
            let remapped = SemanticNode(
                id: id,
                kind: canonical.kind,
                name: canonical.name,
                qualifiedName: canonical.qualifiedName,
                evidence: Array(Set(node.evidence + compilerEvidence)).sorted(by: Evidence.canonicalOrder),
                confidence: .deterministic
            )
            nodesByID[id] = merge(nodesByID[id], remapped)
        }

        let symbols = symbolTable(occurrences)
        for symbol in symbols.values.sorted(by: { $0.usr < $1.usr }) {
            let id = StableID.compilerSymbol(usr: symbol.usr)
            guard nodesByID[id] == nil else { continue }
            let declaration = declarationByUSR[symbol.usr]
            nodesByID[id] = SemanticNode(
                id: id,
                kind: declaration?.kind ?? nodeKind(symbol.kind),
                name: declaration?.name ?? symbol.name,
                qualifiedName: declaration?.qualifiedName ?? "\(symbol.moduleName).\(symbol.name)",
                evidence: Array(Set(symbol.evidence)).sorted(by: Evidence.canonicalOrder),
                confidence: .deterministic
            )
        }

        let remap: (String) -> String = { id in
            syntaxUSR[id].map(StableID.compilerSymbol(usr:)) ?? id
        }
        var edgesByID: [String: SemanticEdge] = [:]
        for edge in graph.edges.sorted(by: { $0.id < $1.id }) {
            _ = addEdge(
                kind: edge.kind,
                from: remap(edge.from),
                to: remap(edge.to),
                evidence: edge.evidence,
                confidence: edge.confidence,
                discriminator: "syntax:\(edge.id)",
                to: &edgesByID
            )
        }

        var indexedFacts = 0
        for occurrence in occurrences {
            let target = StableID.compilerSymbol(usr: occurrence.usr)
            for relation in occurrence.relations.sorted(by: { ($0.roles.rawValue, $0.usr) < ($1.roles.rawValue, $1.usr) }) {
                let related = StableID.compilerSymbol(usr: relation.usr)
                if (occurrence.roles.contains(.definition) || occurrence.roles.contains(.declaration)) && relation.roles.contains(.childOf) {
                    indexedFacts += addEdge(kind: .owns, from: related, to: target, evidence: [occurrence.evidence], confidence: .deterministic, discriminator: "index-child", to: &edgesByID)
                }
                if (occurrence.roles.contains(.definition) || occurrence.roles.contains(.declaration)) && relation.roles.contains(.containedBy) {
                    indexedFacts += addEdge(kind: .owns, from: related, to: target, evidence: [occurrence.evidence], confidence: .deterministic, discriminator: "index-contained", to: &edgesByID)
                }
                if relation.roles.contains(.accessorOf) {
                    indexedFacts += addEdge(kind: .aliases, from: target, to: related, evidence: [occurrence.evidence], confidence: .deterministic, discriminator: "index-accessor", to: &edgesByID)
                }
            }
            let actors = occurrence.relations.filter {
                $0.roles.contains(.calledBy) || $0.roles.contains(.containedBy)
            }.map { StableID.compilerSymbol(usr: $0.usr) }.sorted()
            for actor in Set(actors).sorted() {
                if occurrence.roles.contains(.read) {
                    indexedFacts += addEdge(kind: .reads, from: actor, to: target, evidence: [occurrence.evidence.with(kind: "index-read")], confidence: .deterministic, discriminator: "index-read", to: &edgesByID)
                }
                if occurrence.roles.contains(.write) {
                    indexedFacts += addEdge(kind: .writes, from: actor, to: target, evidence: [occurrence.evidence.with(kind: "index-write")], confidence: .deterministic, discriminator: "index-write", to: &edgesByID)
                }
                if occurrence.roles.contains(.call) {
                    indexedFacts += addEdge(kind: .calls, from: actor, to: target, evidence: [occurrence.evidence.with(kind: "index-call")], confidence: .deterministic, discriminator: "index-call", to: &edgesByID)
                }
            }
        }
        let mappedSymbols = Set(syntaxUSR.values).count
        guard mappedSymbols > 0 || indexedFacts > 0 else {
            return IndexEnrichmentResponse(graph: graph, mappedSymbols: 0, indexedFacts: 0)
        }
        let indexed = SemanticGraph(
            schemaVersion: graph.schemaVersion,
            resolution: "indexed",
            nodes: Array(nodesByID.values),
            edges: Array(edgesByID.values)
        )
        return IndexEnrichmentResponse(graph: indexed, mappedSymbols: mappedSymbols, indexedFacts: indexedFacts)
    }

    private func symbolTable(_ occurrences: [IndexedOccurrence]) -> [String: IndexedSymbol] {
        var result: [String: IndexedSymbol] = [:]
        for occurrence in occurrences {
            result[occurrence.usr] = merge(result[occurrence.usr], occurrence.symbol)
            for relation in occurrence.relations {
                result[relation.usr] = merge(
                    result[relation.usr],
                    relation.symbol(evidence: occurrence.evidence)
                )
            }
        }
        return result
    }

    private func addEdge(
        kind: EdgeKind,
        from: String,
        to: String,
        evidence: [Evidence],
        confidence: Confidence,
        discriminator: String,
        to edges: inout [String: SemanticEdge]
    ) -> Int {
        guard from != to else { return 0 }
        if let existing = edges.values.first(where: {
            $0.kind == kind && $0.from == from && $0.to == to
        }) {
            edges[existing.id] = SemanticEdge(
                id: existing.id, kind: kind, from: from, to: to,
                evidence: Array(Set(existing.evidence + evidence)).sorted(by: Evidence.canonicalOrder),
                confidence: strongest(existing.confidence, confidence)
            )
            return 0
        }
        let id = StableID.edge(kind: kind, from: from, to: to, discriminator: discriminator)
        if let existing = edges[id] {
            edges[id] = SemanticEdge(
                id: id, kind: kind, from: from, to: to,
                evidence: Array(Set(existing.evidence + evidence)).sorted(by: Evidence.canonicalOrder),
                confidence: confidence
            )
            return 0
        }
        edges[id] = SemanticEdge(
            id: id, kind: kind, from: from, to: to,
            evidence: Array(Set(evidence)).sorted(by: Evidence.canonicalOrder), confidence: confidence
        )
        return 1
    }

    private func strongest(_ lhs: Confidence, _ rhs: Confidence) -> Confidence {
        let priority: [Confidence: Int] = [
            .deterministic: 0,
            .strongInference: 1,
            .candidate: 2,
            .llmInferred: 3,
        ]
        return (priority[lhs] ?? 4) <= (priority[rhs] ?? 4) ? lhs : rhs
    }

    private func merge(_ lhs: SemanticNode?, _ rhs: SemanticNode) -> SemanticNode {
        guard let lhs else { return rhs }
        let chosen = preferred(lhs, rhs)
        return SemanticNode(
            id: rhs.id,
            kind: chosen.kind,
            name: chosen.name,
            qualifiedName: chosen.qualifiedName,
            evidence: Array(Set(lhs.evidence + rhs.evidence)).sorted(by: Evidence.canonicalOrder),
            confidence: .deterministic
        )
    }

    private func preferred(_ lhs: SemanticNode, _ rhs: SemanticNode) -> SemanticNode {
        (nodePriority(lhs.kind), lhs.qualifiedName, lhs.id) <= (nodePriority(rhs.kind), rhs.qualifiedName, rhs.id) ? lhs : rhs
    }

    private func merge(_ lhs: IndexedSymbol?, _ rhs: IndexedSymbol) -> IndexedSymbol {
        guard let lhs else { return rhs }
        let chosen = (lhs.name, lhs.moduleName, lhs.usr) <= (rhs.name, rhs.moduleName, rhs.usr) ? lhs : rhs
        return IndexedSymbol(
            usr: chosen.usr, name: chosen.name, kind: chosen.kind, moduleName: chosen.moduleName,
            evidence: Array(Set(lhs.evidence + rhs.evidence)).sorted(by: Evidence.canonicalOrder)
        )
    }

    private func namesMatch(_ syntax: String, _ indexed: String) -> Bool {
        baseName(syntax) == baseName(indexed)
    }

    private func isCompilerResolvableUseSite(_ node: SemanticNode) -> Bool {
        let resolvableEvidence = Set(["member-access", "assignment-target", "function-call", "call-expression"])
        return node.evidence.contains { resolvableEvidence.contains($0.kind) }
    }

    private func occurrenceStartsAtLeaf(
        _ occurrence: IndexedOccurrence,
        sourceLines: [String: [Substring]]
    ) -> Bool {
        guard occurrence.line > 0, occurrence.column > 0,
              let lines = sourceLines[occurrence.file], occurrence.line <= lines.count
        else { return false }
        let bytes = Array(lines[occurrence.line - 1].utf8)
        let leaf = Array(baseName(occurrence.name).utf8)
        let start = occurrence.column - 1
        guard !leaf.isEmpty, start >= 0, start + leaf.count <= bytes.count else { return false }
        return Array(bytes[start..<(start + leaf.count)]) == leaf
    }

    private func sourceLinesByRelativePath(knownPaths: [String: String]) -> [String: [Substring]] {
        var result: [String: [Substring]] = [:]
        for (absolute, relative) in knownPaths.sorted(by: { $0.key < $1.key }) {
            guard let source = try? String(contentsOfFile: absolute, encoding: .utf8) else { continue }
            result[relative] = source.split(separator: "\n", omittingEmptySubsequences: false)
        }
        return result
    }

    private func baseName(_ value: String) -> String {
        String(value.drop(while: { $0 == "$" }).prefix { $0 != "(" && $0 != ":" })
    }

    private func kindsCompatible(_ node: NodeKind, _ symbol: IndexSymbolKind) -> Bool {
        switch node {
        case .type, .view:
            return [.struct, .class, .enum, .protocol, .extension, .typealias].contains(symbol)
        case .function:
            return [.function, .instanceMethod, .classMethod, .staticMethod, .constructor].contains(symbol)
        case .property, .state, .observableState, .binding, .input, .callback, .derivedValue:
            return [.variable, .field, .instanceProperty, .classProperty, .staticProperty, .parameter].contains(symbol)
        default:
            return false
        }
    }

    private func nodeKind(_ symbol: IndexSymbolKind) -> NodeKind {
        switch symbol {
        case .struct, .class, .enum, .protocol, .extension, .typealias: .type
        case .function, .instanceMethod, .classMethod, .staticMethod, .constructor, .destructor, .conversionFunction: .function
        case .parameter: .input
        case .variable, .field, .instanceProperty, .classProperty, .staticProperty: .property
        default: .semanticValue
        }
    }

    private func nodePriority(_ kind: NodeKind) -> Int {
        switch kind {
        case .state, .binding, .observableState, .callback: 0
        case .view, .type, .function, .property, .input, .derivedValue: 1
        default: 2
        }
    }

    private func swiftFiles(at root: URL) -> [URL] {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: root.path, isDirectory: &isDirectory) else { return [] }
        if !isDirectory.boolValue { return root.pathExtension.lowercased() == "swift" ? [root] : [] }
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return [] }
        return enumerator.compactMap { $0 as? URL }.filter {
            $0.pathExtension.lowercased() == "swift" &&
                (try? $0.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true
        }.map { $0.standardizedFileURL.resolvingSymlinksInPath() }.sorted { $0.path < $1.path }
    }

    private func relativePath(for file: URL, root: URL) -> String {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: root.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            return file.lastPathComponent
        }
        let prefix = root.path.hasSuffix("/") ? root.path : root.path + "/"
        return file.path.hasPrefix(prefix)
            ? String(file.path.dropFirst(prefix.count)).replacingOccurrences(of: "\\", with: "/")
            : file.lastPathComponent
    }
}

private struct IndexedOccurrence: Hashable {
    let usr: String
    let name: String
    let kind: IndexSymbolKind
    let file: String
    let line: Int
    let column: Int
    let moduleName: String
    let roles: SymbolRole
    let relations: [IndexedRelation]

    init?(_ occurrence: SymbolOccurrence, knownPaths: [String: String]) {
        let canonical = URL(fileURLWithPath: occurrence.location.path).standardizedFileURL.resolvingSymlinksInPath().path
        guard !occurrence.location.isSystem, let file = knownPaths[canonical] else { return nil }
        self.usr = occurrence.symbol.usr
        self.name = occurrence.symbol.name
        self.kind = occurrence.symbol.kind
        self.file = file
        self.line = occurrence.location.line
        self.column = occurrence.location.utf8Column
        self.moduleName = occurrence.location.moduleName
        self.roles = occurrence.roles
        self.relations = occurrence.relations.map(IndexedRelation.init).sorted {
            ($0.roles.rawValue, $0.usr) < ($1.roles.rawValue, $1.usr)
        }
    }

    var evidence: Evidence { Evidence(file: file, startLine: line, endLine: line, kind: "indexed-occurrence") }
    var symbol: IndexedSymbol {
        IndexedSymbol(usr: usr, name: name, kind: kind, moduleName: moduleName, evidence: [evidence])
    }

    static func canonicalOrder(_ lhs: IndexedOccurrence, _ rhs: IndexedOccurrence) -> Bool {
        (lhs.file, lhs.line, lhs.column, lhs.usr, lhs.roles.rawValue) <
            (rhs.file, rhs.line, rhs.column, rhs.usr, rhs.roles.rawValue)
    }
}

private struct IndexedRelation: Hashable {
    let usr: String
    let name: String
    let kind: IndexSymbolKind
    let roles: SymbolRole

    init(_ relation: SymbolRelation) {
        self.usr = relation.symbol.usr
        self.name = relation.symbol.name
        self.kind = relation.symbol.kind
        self.roles = relation.roles
    }

    func symbol(evidence: Evidence) -> IndexedSymbol {
        IndexedSymbol(usr: usr, name: name, kind: kind, moduleName: "", evidence: [evidence])
    }
}

private struct IndexedSymbol {
    let usr: String
    let name: String
    let kind: IndexSymbolKind
    let moduleName: String
    let evidence: [Evidence]
}

private extension Evidence {
    func with(kind: String) -> Evidence {
        Evidence(file: file, startLine: startLine, endLine: endLine, kind: kind)
    }
}

#else

public struct IndexStoreDBResolver: SymbolResolver, Sendable {
    public init() {}

    public func enrich(_ request: IndexEnrichmentRequest) throws -> IndexEnrichmentResponse {
        throw IndexResolutionError.unavailableLibrary("IndexStoreDB is available only on macOS")
    }
}

#endif
