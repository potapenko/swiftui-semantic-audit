public enum LogicalSourceCounter {
    public static func count(for value: NormalizedSemanticValue, in graph: SemanticGraph) -> Int {
        let representationIDs = Set(value.representations)
        let nodes = Dictionary(uniqueKeysWithValues: graph.nodes.map { ($0.id, $0) })
        let incoming = Dictionary(grouping: graph.edges, by: \.to)

        let owned = representationIDs.filter { id in
            guard let node = nodes[id] else { return false }
            if node.kind == .state { return true }
            if [.binding, .observableState, .input].contains(node.kind) { return false }
            return (incoming[id] ?? []).contains { $0.kind == .writes }
        }.count

        let hasExternalRoot = representationIDs.contains { id in
            guard let node = nodes[id], isBorrowedBoundary(node) else { return false }
            let hasUpstreamRepresentation = (incoming[id] ?? []).contains { edge in
                representationIDs.contains(edge.from) && edge.kind == .passes
            }
            return !hasUpstreamRepresentation
        }
        return owned + (hasExternalRoot ? 1 : 0)
    }

    private static func isBorrowedBoundary(_ node: SemanticNode) -> Bool {
        switch node.kind {
        case .binding:
            return node.evidence.contains { $0.kind == "property-wrapper" }
        case .observableState, .input:
            return node.evidence.contains { $0.kind == "property-wrapper" }
        default:
            return false
        }
    }
}
