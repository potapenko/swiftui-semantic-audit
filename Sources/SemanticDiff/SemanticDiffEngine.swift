import AuditCore
import SnapshotStore

public struct SemanticDiffEngine: Sendable {
    public init() {}

    public func compare(
        base: SemanticSnapshot,
        current: SemanticSnapshot,
        baseIdentity: String? = nil,
        currentIdentity: String? = nil
    ) -> SemanticDiffReport {
        let baseNodes = Dictionary(uniqueKeysWithValues: base.graph.nodes.map { ($0.id, $0) })
        let currentNodes = Dictionary(uniqueKeysWithValues: current.graph.nodes.map { ($0.id, $0) })
        let baseEdges = Dictionary(uniqueKeysWithValues: base.graph.edges.map { ($0.id, $0) })
        let currentEdges = Dictionary(uniqueKeysWithValues: current.graph.edges.map { ($0.id, $0) })
        let baseNodeIDs = Set(baseNodes.keys)
        let currentNodeIDs = Set(currentNodes.keys)
        let baseEdgeIDs = Set(baseEdges.keys)
        let currentEdgeIDs = Set(currentEdges.keys)
        let continuity = NodeContinuity(base: base.graph.nodes, current: current.graph.nodes)
        var changes: [SemanticChange] = []

        for id in currentNodeIDs.subtracting(continuity.currentIDs).sorted() {
            changes.append(SemanticChange(kind: .nodeAdded, nodes: [id]))
        }
        for id in baseNodeIDs.subtracting(continuity.baseIDs).sorted() {
            changes.append(SemanticChange(kind: .nodeRemoved, nodes: [id]))
        }

        let ownershipKinds: Set<EdgeKind> = [.owns, .binds, .injects, .observes]
        for (baseID, currentID) in continuity.pairs.sorted(by: { $0.key < $1.key }) {
            let before = base.graph.edges.filter { $0.to == baseID && ownershipKinds.contains($0.kind) }
            let after = current.graph.edges.filter { $0.to == currentID && ownershipKinds.contains($0.kind) }
            let beforeDescription = ownershipDescription(
                node: baseNodes[baseID]!, edges: before, canonicalNode: { $0 }
            )
            let afterDescription = ownershipDescription(
                node: currentNodes[currentID]!, edges: after, canonicalNode: continuity.canonicalCurrentID
            )
            if beforeDescription != afterDescription {
                changes.append(SemanticChange(
                    kind: .ownershipChanged,
                    nodes: [baseID, currentID] + before.map(\.from) + after.map(\.from),
                    beforeEdges: before.map(\.id),
                    afterEdges: after.map(\.id),
                    before: beforeDescription,
                    after: afterDescription
                ))
            }
        }

        let removedEdges = baseEdgeIDs.subtracting(currentEdgeIDs).compactMap { baseEdges[$0] }
        let addedEdges = currentEdgeIDs.subtracting(baseEdgeIDs).compactMap { currentEdges[$0] }
        appendPathChanges(edges: removedEdges, added: false, to: &changes)
        appendPathChanges(edges: addedEdges, added: true, to: &changes)

        let changedDerivationNodes = Set(
            (removedEdges + addedEdges).filter { $0.kind == .derivesFrom }.map(\.from)
        )
        for nodeID in changedDerivationNodes.sorted() {
            let before = base.graph.edges.filter { $0.kind == .derivesFrom && $0.from == nodeID }
            let after = current.graph.edges.filter { $0.kind == .derivesFrom && $0.from == nodeID }
            changes.append(SemanticChange(
                kind: .derivationChanged,
                nodes: [nodeID] + before.map(\.to) + after.map(\.to),
                beforeEdges: before.map(\.id),
                afterEdges: after.map(\.id)
            ))
        }

        let findingDelta = findingDelta(
            base: base.report.findings,
            current: current.report.findings,
            continuity: continuity
        )
        let newFindings = findingDelta.new
        let resolvedFindings = findingDelta.resolved
        for finding in newFindings where finding.rule == .manualTwoWaySync {
            changes.append(SemanticChange(
                kind: .manualSyncAdded,
                nodes: finding.nodes,
                afterEdges: finding.edges
            ))
        }
        for finding in resolvedFindings where finding.rule == .manualTwoWaySync {
            changes.append(SemanticChange(
                kind: .manualSyncRemoved,
                nodes: finding.nodes,
                beforeEdges: finding.edges
            ))
        }

        let valueDeltas = semanticValueDeltas(
            base: base,
            current: current,
            changedNodes: baseNodeIDs.symmetricDifference(currentNodeIDs),
            changedEdges: baseEdgeIDs.symmetricDifference(currentEdgeIDs),
            findings: newFindings + resolvedFindings,
            continuity: continuity
        )
        for delta in valueDeltas where isSourceCountChange(delta) {
            changes.append(SemanticChange(
                kind: .sourceOfTruthCountChanged,
                semanticValues: [delta.id],
                before: countPayload(
                    representations: delta.beforeRepresentationCount ?? 0,
                    sources: delta.beforeSourceCount ?? 0
                ),
                after: countPayload(
                    representations: delta.afterRepresentationCount ?? 0,
                    sources: delta.afterSourceCount ?? 0
                )
            ))
        }

        return SemanticDiffReport(
            baseIdentity: baseIdentity ?? identity(for: base.manifest),
            currentIdentity: currentIdentity ?? identity(for: current.manifest),
            beforeMetrics: base.report.metrics,
            afterMetrics: current.report.metrics,
            changes: changes,
            newFindings: newFindings,
            resolvedFindings: resolvedFindings,
            affectedSemanticValues: valueDeltas
        )
    }

    public func humanDescription(_ report: SemanticDiffReport) -> String {
        var lines = ["Semantic data-flow diff", ""]
        let metrics: [(String, Int, Int)] = [
            ("Manual synchronization", report.beforeMetrics.manualSynchronizationEdges, report.afterMetrics.manualSynchronizationEdges),
            ("Duplicated sources of truth", report.beforeMetrics.duplicatedSourcesOfTruth, report.afterMetrics.duplicatedSourcesOfTruth),
            ("Binding paths", report.beforeMetrics.bindingEdges, report.afterMetrics.bindingEdges),
            ("Callback tunnels", report.beforeMetrics.callbackTunnels, report.afterMetrics.callbackTunnels),
            ("Derived mutable state", report.beforeMetrics.derivedMutableValues, report.afterMetrics.derivedMutableValues),
        ]
        for metric in metrics { lines.append("\(metric.0): \(metric.1) -> \(metric.2)") }
        lines.append("")
        lines.append("Changes: \(report.changes.count)")
        for kind in SemanticChangeKind.allCases {
            let count = report.changes.filter { $0.kind == kind }.count
            if count > 0 { lines.append("\(kind.rawValue): \(count)") }
        }
        lines.append("New findings: \(report.newFindings.count)")
        lines.append("Resolved findings: \(report.resolvedFindings.count)")
        lines.append("Affected semantic values: \(report.affectedSemanticValues.count)")
        return lines.joined(separator: "\n") + "\n"
    }

    private func appendPathChanges(edges: [SemanticEdge], added: Bool, to changes: inout [SemanticChange]) {
        for edge in edges.sorted(by: { $0.id < $1.id }) {
            let kind: SemanticChangeKind?
            switch (edge.kind, added) {
            case (.reads, true): kind = .readPathAdded
            case (.reads, false): kind = .readPathRemoved
            case (.writes, true): kind = .writePathAdded
            case (.writes, false): kind = .writePathRemoved
            case (.binds, true): kind = .bindingAdded
            case (.binds, false): kind = .bindingRemoved
            default: kind = nil
            }
            guard let kind else { continue }
            changes.append(SemanticChange(
                kind: kind,
                nodes: [edge.from, edge.to],
                beforeEdges: added ? [] : [edge.id],
                afterEdges: added ? [edge.id] : []
            ))
        }
    }

    private func semanticValueDeltas(
        base: SemanticSnapshot,
        current: SemanticSnapshot,
        changedNodes: Set<String>,
        changedEdges: Set<String>,
        findings: [AuditFinding],
        continuity: NodeContinuity
    ) -> [SemanticValueDelta] {
        let findingNodes = Set(findings.flatMap(\.nodes))
        let findingEdges = Set(findings.flatMap(\.edges))
        let matches = semanticValueMatches(
            base: base.report.semanticValues,
            current: current.report.semanticValues,
            continuity: continuity
        )
        return matches.compactMap { match in
            let lhs = match.before
            let rhs = match.after
            let representations = Set((lhs?.representations ?? []) + (rhs?.representations ?? []))
            let relations = Set((lhs?.relationEdges ?? []) + (rhs?.relationEdges ?? []))
            let beforeCount = lhs.map { sourceCount($0, graph: base.graph) }
            let afterCount = rhs.map { sourceCount($0, graph: current.graph) }
            let affected = lhs == nil || rhs == nil || beforeCount != afterCount ||
                !representations.isDisjoint(with: changedNodes) ||
                !relations.isDisjoint(with: changedEdges) ||
                !representations.isDisjoint(with: findingNodes) ||
                !relations.isDisjoint(with: findingEdges)
            guard affected else { return nil }
            return SemanticValueDelta(
                id: match.id,
                beforeRepresentations: lhs?.representations ?? [],
                afterRepresentations: rhs?.representations ?? [],
                beforeRepresentationCount: lhs?.representations.count,
                afterRepresentationCount: rhs?.representations.count,
                beforeSourceCount: beforeCount,
                afterSourceCount: afterCount
            )
        }.sorted { $0.id < $1.id }
    }

    private func semanticValueMatches(
        base: [NormalizedSemanticValue],
        current: [NormalizedSemanticValue],
        continuity: NodeContinuity
    ) -> [SemanticValueMatch] {
        var unmatchedBase = Dictionary(uniqueKeysWithValues: base.map { ($0.id, $0) })
        var unmatchedCurrent = Dictionary(uniqueKeysWithValues: current.map { ($0.id, $0) })
        var result: [SemanticValueMatch] = []

        for id in Set(unmatchedBase.keys).intersection(unmatchedCurrent.keys).sorted() {
            result.append(SemanticValueMatch(id: id, before: unmatchedBase.removeValue(forKey: id), after: unmatchedCurrent.removeValue(forKey: id)))
        }

        let baseSets = unmatchedBase.mapValues { Set($0.representations) }
        let currentSets = unmatchedCurrent.mapValues { Set($0.representations.map(continuity.canonicalCurrentID)) }
        var pairedBase: Set<String> = []
        var pairedCurrent: Set<String> = []
        for baseID in unmatchedBase.keys.sorted() {
            let candidates = unmatchedCurrent.keys.filter { currentID in
                !baseSets[baseID]!.isDisjoint(with: currentSets[currentID]!)
            }.sorted()
            guard candidates.count == 1, let currentID = candidates.first else { continue }
            let reverse = unmatchedBase.keys.filter { candidateBaseID in
                !baseSets[candidateBaseID]!.isDisjoint(with: currentSets[currentID]!)
            }
            guard reverse.count == 1 else { continue }
            pairedBase.insert(baseID)
            pairedCurrent.insert(currentID)
            result.append(SemanticValueMatch(
                id: baseID,
                before: unmatchedBase[baseID],
                after: unmatchedCurrent[currentID]
            ))
        }
        for id in unmatchedBase.keys where !pairedBase.contains(id) {
            result.append(SemanticValueMatch(id: id, before: unmatchedBase[id], after: nil))
        }
        for id in unmatchedCurrent.keys where !pairedCurrent.contains(id) {
            result.append(SemanticValueMatch(id: id, before: nil, after: unmatchedCurrent[id]))
        }
        return result.sorted { $0.id < $1.id }
    }

    private func findingDelta(
        base: [AuditFinding],
        current: [AuditFinding],
        continuity: NodeContinuity
    ) -> (new: [AuditFinding], resolved: [AuditFinding]) {
        let exactIDs = Set(base.map(\.id)).intersection(current.map(\.id))
        let before = Dictionary(grouping: base.filter { !exactIDs.contains($0.id) }, by: {
            findingIdentity($0, canonicalNode: { $0 })
        })
            .mapValues { $0.sorted { $0.id < $1.id } }
        let after = Dictionary(grouping: current.filter { !exactIDs.contains($0.id) }, by: {
            findingIdentity($0, canonicalNode: continuity.canonicalCurrentID)
        }).mapValues { $0.sorted { $0.id < $1.id } }
        var introduced: [AuditFinding] = []
        var resolved: [AuditFinding] = []
        for key in Set(before.keys).union(after.keys).sorted() {
            let lhs = before[key] ?? []
            let rhs = after[key] ?? []
            let continuityCandidates = lhs.indices.filter { index in
                index < rhs.count && lhs[index].nodes != rhs[index].nodes
            }.count
            let continuityMatches = min(lhs.count, min(rhs.count, continuityCandidates))
            introduced.append(contentsOf: rhs.dropFirst(continuityMatches))
            resolved.append(contentsOf: lhs.dropFirst(continuityMatches))
        }
        return (introduced, resolved)
    }

    private func findingIdentity(
        _ finding: AuditFinding,
        canonicalNode: (String) -> String
    ) -> String {
        [
            finding.rule.rawValue,
            finding.nodes.map(canonicalNode).sorted().joined(separator: ","),
            finding.depth.map(String.init) ?? "",
        ].joined(separator: "|")
    }

    private func ownershipDescription(
        node: SemanticNode,
        edges: [SemanticEdge],
        canonicalNode: (String) -> String
    ) -> String {
        let role: String
        switch node.kind {
        case .binding: role = "ownership=borrowed;access=read-write;lifetime=upstream"
        case .state: role = "ownership=owned;access=read-write;lifetime=view-local"
        case .observableState: role = "ownership=observed;access=read-write;lifetime=external"
        case .input: role = "ownership=borrowed;access=read-only;lifetime=upstream"
        case .property: role = "ownership=stored;access=syntax-dependent;lifetime=declaration"
        default: role = "ownership=structural;access=syntax-dependent;lifetime=declaration"
        }
        let owners = edges.map { "\($0.kind.rawValue):\(canonicalNode($0.from))" }.sorted().joined(separator: ",")
        return "kind=\(node.kind.rawValue);\(role);owners=\(owners)"
    }

    private func isSourceCountChange(_ delta: SemanticValueDelta) -> Bool {
        let before = delta.beforeSourceCount ?? 0
        let after = delta.afterSourceCount ?? 0
        return before != after && (before > 0 || after > 0)
    }

    private func countPayload(representations: Int, sources: Int) -> String {
        "representations=\(representations);sources=\(sources)"
    }

    private func sourceCount(_ value: NormalizedSemanticValue, graph: SemanticGraph) -> Int {
        let nodes = Dictionary(uniqueKeysWithValues: graph.nodes.map { ($0.id, $0) })
        return value.representations.filter { id in
            guard let node = nodes[id] else { return false }
            if node.kind == .state || node.kind == .observableState { return true }
            if node.kind == .binding { return false }
            return graph.edges.contains { $0.kind == .writes && $0.to == id }
        }.count
    }

    private func identity(for manifest: SnapshotManifest) -> String {
        manifest.repositoryRevision == "unavailable"
            ? "snapshot:\(manifest.generatedFrom)"
            : manifest.repositoryRevision
    }
}

private struct SemanticValueMatch {
    let id: String
    let before: NormalizedSemanticValue?
    let after: NormalizedSemanticValue?
}

private struct NodeContinuity {
    let pairs: [String: String]
    let currentToBase: [String: String]

    init(base: [SemanticNode], current: [SemanticNode]) {
        let baseByID = Dictionary(uniqueKeysWithValues: base.map { ($0.id, $0) })
        let currentByID = Dictionary(uniqueKeysWithValues: current.map { ($0.id, $0) })
        var matches = Dictionary(uniqueKeysWithValues: Set(baseByID.keys).intersection(currentByID.keys).map { ($0, $0) })
        let exactBase = Set(matches.keys)
        let exactCurrent = Set(matches.values)
        let baseCandidates = Dictionary(grouping: base.filter {
            !exactBase.contains($0.id) && Self.compatibleRepresentationKinds.contains($0.kind)
        }, by: Self.declarationKey)
        let currentCandidates = Dictionary(grouping: current.filter {
            !exactCurrent.contains($0.id) && Self.compatibleRepresentationKinds.contains($0.kind)
        }, by: Self.declarationKey)
        for key in Set(baseCandidates.keys).intersection(currentCandidates.keys).sorted() {
            guard let lhs = baseCandidates[key], lhs.count == 1,
                  let rhs = currentCandidates[key], rhs.count == 1,
                  lhs[0].kind != rhs[0].kind
            else { continue }
            matches[lhs[0].id] = rhs[0].id
        }
        self.pairs = matches
        self.currentToBase = Dictionary(uniqueKeysWithValues: matches.map { ($0.value, $0.key) })
    }

    var baseIDs: Set<String> { Set(pairs.keys) }
    var currentIDs: Set<String> { Set(pairs.values) }

    func canonicalCurrentID(_ id: String) -> String {
        currentToBase[id] ?? id
    }

    private static let compatibleRepresentationKinds: Set<NodeKind> = [
        .property, .state, .binding, .input, .observableState,
    ]

    private static func declarationKey(_ node: SemanticNode) -> String {
        let scope = node.qualifiedName.split(separator: ".").dropLast().joined(separator: ".")
        return [scope, node.name, node.qualifiedName].joined(separator: "|")
    }
}
