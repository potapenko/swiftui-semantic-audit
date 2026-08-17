import AuditCore

public struct NormalizationResult: Sendable {
    public let semanticValues: [NormalizedSemanticValue]
    public let valueByRepresentation: [String: NormalizedSemanticValue]

    public init(semanticValues: [NormalizedSemanticValue]) {
        self.semanticValues = semanticValues.sorted { $0.id < $1.id }
        self.valueByRepresentation = Dictionary(
            uniqueKeysWithValues: semanticValues.flatMap { value in
                value.representations.map { ($0, value) }
            }
        )
    }
}

public struct SemanticNormalizer: Sendable {
    public init() {}

    public func normalize(_ graph: SemanticGraph) -> NormalizationResult {
        let nodes = Dictionary(uniqueKeysWithValues: graph.nodes.map { ($0.id, $0) })
        let representationIDs = graph.nodes.filter { Self.isRepresentation($0) }.map(\.id).sorted()
        var unionFind = UnionFind(elements: representationIDs)

        let relationEdges = graph.edges.filter { edge in
            guard let from = nodes[edge.from], let to = nodes[edge.to],
                  Self.isRepresentation(from), Self.isRepresentation(to)
            else { return false }
            switch edge.kind {
            case .copiesTo:
                return edge.evidence.contains { $0.kind == "assignment" }
            case .aliases:
                return edge.evidence.contains { $0.kind == "binding-projection" }
            case .passes:
                return edge.evidence.contains { $0.kind == "initializer-argument" }
            default:
                return false
            }
        }
        for edge in relationEdges {
            unionFind.union(edge.from, edge.to)
        }

        let grouped = Dictionary(grouping: representationIDs, by: { unionFind.find($0) })
        let semanticValues = grouped.values.map { representations -> NormalizedSemanticValue in
            let canonicalRepresentations = representations.sorted()
            let representationSet = Set(canonicalRepresentations)
            let relations = relationEdges.filter {
                representationSet.contains($0.from) && representationSet.contains($0.to)
            }
            let classification = transactionalClassification(
                representations: representationSet,
                graph: graph,
                nodes: nodes
            )
            let supportingEdges = relations + (classification?.edges ?? [])
            return NormalizedSemanticValue(
                id: StableID.semanticValue(representations: canonicalRepresentations),
                representations: canonicalRepresentations,
                relationEdges: supportingEdges.map(\.id),
                confidence: classification == nil ? .deterministic : .strongInference,
                classification: classification?.classification,
                evidence: supportingEdges.flatMap(\.evidence)
            )
        }
        return NormalizationResult(semanticValues: semanticValues)
    }

    public static func isRepresentation(_ node: SemanticNode) -> Bool {
        switch node.kind {
        case .property, .state, .observableState, .binding, .input, .derivedValue, .semanticValue:
            true
        default:
            false
        }
    }

    private func transactionalClassification(
        representations: Set<String>,
        graph: SemanticGraph,
        nodes: [String: SemanticNode]
    ) -> ClassificationMatch? {
        let localStates = representations.filter { nodes[$0]?.kind == .state }.sorted()
        guard localStates.count == 1 else { return nil }
        let local = localStates[0]
        guard let localOwner = declarationOwner(of: local, graph: graph, nodes: nodes) else { return nil }
        let upstreams = representations.filter { $0 != local && nodes[$0]?.kind != .binding }.sorted()
        guard !upstreams.isEmpty else { return nil }
        let identityEdges = graph.edges.filter {
            $0.kind == .copiesTo && representations.contains($0.from) && representations.contains($0.to)
        }
        guard let initialSync = identityEdges.first(where: {
            upstreams.contains($0.from) && $0.to == local
        }) else { return nil }

        let actionFlows = graph.nodes.filter {
            $0.kind == .event && $0.evidence.contains { $0.kind == "swiftui-action" } &&
                declarationOwner(of: $0.id, graph: graph, nodes: nodes) == localOwner
        }.sorted { $0.id < $1.id }.map { actionFlow(from: $0.id, graph: graph) }

        for commit in actionFlows {
            guard let commitCopy = identityEdges.first(where: { edge in
                edge.from == local && upstreams.contains(edge.to) && actionContains(edge: edge, flow: commit)
            }) else { continue }
            for discard in actionFlows where discard.actionID != commit.actionID {
                guard !discard.writes.contains(where: { upstreams.contains($0.to) }),
                      let discardCopy = identityEdges.first(where: { edge in
                          upstreams.contains(edge.from) && edge.to == local && actionContains(edge: edge, flow: discard)
                      })
                else { continue }
                return ClassificationMatch(
                    classification: .transactionalDraft,
                    edges: ([initialSync, commitCopy, discardCopy]
                        + commit.traversalEdges + commit.writes
                        + discard.traversalEdges + discard.writes)
                        .sorted { $0.id < $1.id }
                )
            }
        }
        return nil
    }

    private func actionFlow(from actionID: String, graph: SemanticGraph) -> ActionFlow {
        let traversable: Set<EdgeKind> = [.creates, .calls]
        var actors: Set<String> = [actionID]
        var queue = [actionID]
        var traversalEdges = graph.edges.filter {
            $0.to == actionID && $0.kind == .creates && $0.evidence.contains { $0.kind == "swiftui-action" }
        }
        while let current = queue.first, actors.count < 128 {
            queue.removeFirst()
            for edge in graph.edges where edge.from == current && traversable.contains(edge.kind) {
                traversalEdges.append(edge)
                if actors.insert(edge.to).inserted { queue.append(edge.to) }
            }
        }
        return ActionFlow(
            actionID: actionID,
            traversalEdges: traversalEdges.sorted { $0.id < $1.id },
            writes: graph.edges.filter { $0.kind == .writes && actors.contains($0.from) }.sorted { $0.id < $1.id }
        )
    }

    private func actionContains(edge: SemanticEdge, flow: ActionFlow) -> Bool {
        let writeEvidence = Set(flow.writes.flatMap(\.evidence).map(EvidenceKey.init))
        return edge.evidence.contains { writeEvidence.contains(EvidenceKey($0)) }
    }

    private func declarationOwner(
        of nodeID: String,
        graph: SemanticGraph,
        nodes: [String: SemanticNode]
    ) -> String? {
        let ownershipKinds: Set<EdgeKind> = [.owns, .binds, .injects, .observes, .creates]
        var visited: Set<String> = [nodeID]
        var queue = [nodeID]
        while let current = queue.first, visited.count < 128 {
            queue.removeFirst()
            for edge in graph.edges where edge.to == current && ownershipKinds.contains(edge.kind) {
                if let owner = nodes[edge.from], owner.kind == .view || owner.kind == .type {
                    return owner.id
                }
                if visited.insert(edge.from).inserted { queue.append(edge.from) }
            }
        }
        return nil
    }
}

private struct ClassificationMatch {
    let classification: SemanticClassification
    let edges: [SemanticEdge]
}

private struct ActionFlow {
    let actionID: String
    let traversalEdges: [SemanticEdge]
    let writes: [SemanticEdge]
}

private struct EvidenceKey: Hashable {
    let file: String
    let startLine: Int
    let endLine: Int

    init(_ evidence: Evidence) {
        self.file = evidence.file
        self.startLine = evidence.startLine
        self.endLine = evidence.endLine
    }
}

private struct UnionFind {
    private var parent: [String: String]

    init(elements: [String]) {
        self.parent = Dictionary(uniqueKeysWithValues: elements.map { ($0, $0) })
    }

    mutating func find(_ element: String) -> String {
        guard let immediate = parent[element] else { return element }
        if immediate == element { return element }
        let root = find(immediate)
        parent[element] = root
        return root
    }

    mutating func union(_ lhs: String, _ rhs: String) {
        let lhsRoot = find(lhs)
        let rhsRoot = find(rhs)
        guard lhsRoot != rhsRoot else { return }
        let root = min(lhsRoot, rhsRoot)
        let child = max(lhsRoot, rhsRoot)
        parent[child] = root
    }
}
