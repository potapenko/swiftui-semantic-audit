public enum LogicalSourceCounter {
    public struct Context: Sendable {
        private let nodesByID: [String: SemanticNode]
        private let incomingEdgesByTarget: [String: [SemanticEdge]]

        public init(graph: SemanticGraph) {
            self.nodesByID = Dictionary(uniqueKeysWithValues: graph.nodes.map { ($0.id, $0) })
            self.incomingEdgesByTarget = Dictionary(grouping: graph.edges, by: \.to)
        }

        public func count(for value: NormalizedSemanticValue) -> Int {
            let representationIDs = Set(value.representations)

            let owned = representationIDs.filter { id in
                guard let node = nodesByID[id] else { return false }
                if node.kind == .state { return true }
                if [.binding, .observableState, .input].contains(node.kind) { return false }
                return (incomingEdgesByTarget[id] ?? []).contains { $0.kind == .writes }
            }.count

            let hasExternalRoot = representationIDs.contains { id in
                guard let node = nodesByID[id], LogicalSourceCounter.isBorrowedBoundary(node) else {
                    return false
                }
                let hasUpstreamRepresentation = (incomingEdgesByTarget[id] ?? []).contains { edge in
                    representationIDs.contains(edge.from) && edge.kind == .passes
                }
                return !hasUpstreamRepresentation
            }
            return owned + (hasExternalRoot ? 1 : 0)
        }
    }

    public static func count(for value: NormalizedSemanticValue, in graph: SemanticGraph) -> Int {
        Context(graph: graph).count(for: value)
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
