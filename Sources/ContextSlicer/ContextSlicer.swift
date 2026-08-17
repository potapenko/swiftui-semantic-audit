import AuditCore
import Foundation

public struct ContextSlicer: Sendable {
    public init() {}

    public func slice(
        graph: SemanticGraph,
        report: AuditReport,
        findingID: String,
        tokenBudget: Int? = nil
    ) throws -> ContextSlice {
        guard let finding = report.findings.first(where: { $0.id == findingID }) else {
            throw ContextSliceError.unknownFinding(findingID)
        }
        return try build(
            graph: graph,
            report: report,
            finding: finding,
            coreNodeIDs: Set(finding.nodes),
            selection: "finding:\(findingID)",
            tokenBudget: tokenBudget
        )
    }

    public func slice(
        graph: SemanticGraph,
        report: AuditReport,
        symbol: String,
        tokenBudget: Int? = nil
    ) throws -> ContextSlice {
        let node = try resolve(symbol: symbol, in: graph)
        let value = report.semanticValues.first { $0.representations.contains(node.id) }
        let relatedIDs = Set([node.id] + (value?.representations ?? []))
        let finding = report.findings.first { !relatedIDs.isDisjoint(with: $0.nodes) }
        return try build(
            graph: graph,
            report: report,
            finding: finding,
            coreNodeIDs: [node.id],
            selection: "symbol:\(node.id)",
            tokenBudget: tokenBudget
        )
    }

    public func humanDescription(_ slice: ContextSlice) -> String {
        let nodeByID = Dictionary(uniqueKeysWithValues: slice.nodes.map { ($0.id, $0) })
        var lines: [String] = []
        lines.append("OWNER")
        let ownerEdges = slice.edges.filter { [.owns, .binds, .injects, .observes].contains($0.kind) }
        if ownerEdges.isEmpty {
            lines.append("  unknown")
        } else {
            for edge in ownerEdges {
                lines.append("  \(nodeByID[edge.from]?.qualifiedName ?? edge.from) -> \(nodeByID[edge.to]?.qualifiedName ?? edge.to)")
            }
        }
        lines.append("")
        lines.append("READ PATH")
        appendPaths(kind: .reads, slice: slice, nodes: nodeByID, to: &lines)
        lines.append("")
        lines.append("WRITE PATH")
        appendPaths(kind: .writes, slice: slice, nodes: nodeByID, to: &lines)
        lines.append("")
        lines.append("FINDING")
        if let finding = slice.finding {
            lines.append("  \(finding.rule.rawValue) [\(finding.confidence.rawValue)]")
        } else {
            lines.append("  none")
        }
        lines.append("")
        lines.append("SOURCE EVIDENCE")
        for evidence in slice.sourceEvidence {
            lines.append("  \(evidence.file):\(evidence.startLine)-\(evidence.endLine) \(evidence.kind)")
        }
        if slice.metadata.truncated {
            lines.append("")
            lines.append("TRUNCATED at approximately \(slice.metadata.estimatedTokens) tokens")
        }
        return lines.joined(separator: "\n") + "\n"
    }

    private func build(
        graph: SemanticGraph,
        report: AuditReport,
        finding: AuditFinding?,
        coreNodeIDs: Set<String>,
        selection: String,
        tokenBudget: Int?
    ) throws -> ContextSlice {
        if let tokenBudget, tokenBudget <= 0 { throw ContextSliceError.invalidBudget(tokenBudget) }
        let nodeByID = Dictionary(uniqueKeysWithValues: graph.nodes.map { ($0.id, $0) })
        let edgeByID = Dictionary(uniqueKeysWithValues: graph.edges.map { ($0.id, $0) })
        var mandatoryNodes = coreNodeIDs
        var mandatoryEdges = Set(finding?.edges ?? [])
        mandatoryNodes.formUnion(finding?.nodes ?? [])

        let seedValues = report.semanticValues.filter { value in
            !Set(value.representations).isDisjoint(with: mandatoryNodes) ||
                !Set(value.relationEdges).isDisjoint(with: mandatoryEdges)
        }
        for value in seedValues {
            mandatoryNodes.formUnion(value.representations)
            mandatoryEdges.formUnion(value.relationEdges)
        }
        for id in mandatoryEdges {
            if let edge = edgeByID[id] {
                mandatoryNodes.insert(edge.from)
                mandatoryNodes.insert(edge.to)
            }
        }

        let expanded = expand(
            from: mandatoryNodes,
            mandatoryEdges: mandatoryEdges,
            graph: graph,
            nodeByID: nodeByID
        )
        let questions = questionsFor(finding: finding, selection: selection)
        let full = makeSlice(
            finding: finding,
            semanticValues: seedValues,
            nodeIDs: expanded.nodes,
            edgeIDs: expanded.edges,
            graph: graph,
            questions: questions,
            selection: selection,
            tokenBudget: tokenBudget,
            truncated: false
        )
        guard let tokenBudget else { return withAccurateEstimate(full) }
        let measuredFull = withAccurateEstimate(full)
        if measuredFull.metadata.estimatedTokens <= tokenBudget { return measuredFull }

        var selectedNodes = mandatoryNodes
        var selectedEdges = mandatoryEdges
        func mandatorySlice(budget: Int) -> ContextSlice {
            withAccurateEstimate(makeSlice(
                finding: finding,
                semanticValues: seedValues,
                nodeIDs: selectedNodes,
                edgeIDs: selectedEdges,
                graph: graph,
                questions: questions,
                selection: selection,
                tokenBudget: budget,
                truncated: true
            ))
        }
        let minimumBudget = fixedPointMinimum { mandatorySlice(budget: $0).metadata.estimatedTokens }
        guard tokenBudget >= minimumBudget else {
            throw ContextSliceError.insufficientBudget(
                requested: tokenBudget,
                minimum: minimumBudget
            )
        }
        let mandatory = mandatorySlice(budget: tokenBudget)

        let optionalEdges = expanded.edges.subtracting(mandatoryEdges).compactMap { edgeByID[$0] }.sorted {
            (Self.priority($0.kind), $0.id) < (Self.priority($1.kind), $1.id)
        }
        var current = mandatory
        for edge in optionalEdges {
            var candidateNodes = selectedNodes
            candidateNodes.insert(edge.from)
            candidateNodes.insert(edge.to)
            var candidateEdges = selectedEdges
            candidateEdges.insert(edge.id)
            let candidate = withAccurateEstimate(makeSlice(
                finding: finding,
                semanticValues: seedValues,
                nodeIDs: candidateNodes,
                edgeIDs: candidateEdges,
                graph: graph,
                questions: questions,
                selection: selection,
                tokenBudget: tokenBudget,
                truncated: true
            ))
            if candidate.metadata.estimatedTokens <= tokenBudget {
                selectedNodes = candidateNodes
                selectedEdges = candidateEdges
                current = candidate
            }
        }
        return current
    }

    private func resolve(symbol: String, in graph: SemanticGraph) throws -> SemanticNode {
        if let exactID = graph.nodes.first(where: { $0.id == symbol }) { return exactID }
        if let exactName = graph.nodes.first(where: { $0.qualifiedName == symbol }) { return exactName }
        let suffixMatches = graph.nodes.filter {
            $0.qualifiedName == symbol || $0.qualifiedName.hasSuffix(".\(symbol)")
        }.sorted { $0.qualifiedName < $1.qualifiedName }
        if suffixMatches.count == 1 { return suffixMatches[0] }
        if suffixMatches.count > 1 {
            throw ContextSliceError.ambiguousSymbol(symbol, suffixMatches.map(\.qualifiedName))
        }
        throw ContextSliceError.unknownSymbol(symbol)
    }

    private func expand(
        from seeds: Set<String>,
        mandatoryEdges: Set<String>,
        graph: SemanticGraph,
        nodeByID: [String: SemanticNode]
    ) -> (nodes: Set<String>, edges: Set<String>) {
        let relevant: Set<EdgeKind> = [
            .owns, .reads, .writes, .binds, .observes, .injects, .passes, .calls,
            .sets, .copiesTo, .derivesFrom, .triggers, .aliases, .creates,
        ]
        var nodes = seeds
        var edges = mandatoryEdges
        var visited = seeds
        var queue = seeds.sorted().map { ($0, 0) }
        while let (current, depth) = queue.first, visited.count < 256 {
            queue.removeFirst()
            guard depth < 3 else { continue }
            for edge in graph.edges where relevant.contains(edge.kind) && (edge.from == current || edge.to == current) {
                let hierarchical = edge.kind == .owns || edge.kind == .creates
                if hierarchical && edge.to != current && !mandatoryEdges.contains(edge.id) { continue }
                let other = edge.from == current ? edge.to : edge.from
                edges.insert(edge.id)
                nodes.insert(edge.from)
                nodes.insert(edge.to)
                if nodeByID[other]?.kind != .module, visited.insert(other).inserted {
                    queue.append((other, depth + 1))
                }
            }
        }
        return (nodes, edges)
    }

    private func makeSlice(
        finding: AuditFinding?,
        semanticValues: [NormalizedSemanticValue],
        nodeIDs: Set<String>,
        edgeIDs: Set<String>,
        graph: SemanticGraph,
        questions: [String],
        selection: String,
        tokenBudget: Int?,
        truncated: Bool
    ) -> ContextSlice {
        let nodes = graph.nodes.filter { nodeIDs.contains($0.id) }
        let retainedNodeIDs = Set(nodes.map(\.id))
        let edges = graph.edges.filter {
            edgeIDs.contains($0.id) && retainedNodeIDs.contains($0.from) && retainedNodeIDs.contains($0.to)
        }
        let evidence = nodes.flatMap(\.evidence) + edges.flatMap(\.evidence) +
            semanticValues.flatMap(\.evidence) + (finding?.evidence ?? [])
        return ContextSlice(
            finding: finding,
            semanticValues: semanticValues,
            nodes: nodes,
            edges: edges,
            sourceEvidence: evidence,
            questions: questions,
            metadata: SliceMetadata(
                selection: selection,
                tokenBudget: tokenBudget,
                estimatedTokens: 0,
                truncated: truncated
            )
        )
    }

    private func withAccurateEstimate(_ slice: ContextSlice) -> ContextSlice {
        var estimate = 0
        var result = slice
        for _ in 0..<4 {
            result = ContextSlice(
                finding: slice.finding,
                semanticValues: slice.semanticValues,
                nodes: slice.nodes,
                edges: slice.edges,
                sourceEvidence: slice.sourceEvidence,
                questions: slice.questions,
                metadata: SliceMetadata(
                    selection: slice.metadata.selection,
                    tokenBudget: slice.metadata.tokenBudget,
                    estimatedTokens: estimate,
                    truncated: slice.metadata.truncated
                )
            )
            let bytes = (try? result.jsonData().count) ?? Int.max / 2
            let next = max(1, (bytes + 2) / 3)
            if next == estimate { break }
            estimate = next
        }
        return ContextSlice(
            finding: result.finding,
            semanticValues: result.semanticValues,
            nodes: result.nodes,
            edges: result.edges,
            sourceEvidence: result.sourceEvidence,
            questions: result.questions,
            metadata: SliceMetadata(
                selection: result.metadata.selection,
                tokenBudget: result.metadata.tokenBudget,
                estimatedTokens: estimate,
                truncated: result.metadata.truncated
            )
        )
    }

    private func fixedPointMinimum(estimate: (Int) -> Int) -> Int {
        var upper = 1
        for _ in 0..<16 {
            let measured = estimate(upper)
            if measured <= upper { break }
            upper = measured
        }
        var lower = 1
        while lower < upper {
            let middle = lower + (upper - lower) / 2
            if estimate(middle) <= middle {
                upper = middle
            } else {
                lower = middle + 1
            }
        }
        return lower
    }

    private func questionsFor(finding: AuditFinding?, selection: String) -> [String] {
        if let finding {
            return [
                "Which representation should own the affected semantic value?",
                "Does the evidence support \(finding.rule.rawValue), an intentional transformation, or transactional behavior?",
            ]
        }
        return [
            "Who owns the selected symbol?",
            "Which read and write paths should remain canonical?",
            "Is the selected value stored, derived, bound, or transactionally edited?",
        ]
    }

    private static func priority(_ kind: EdgeKind) -> Int {
        switch kind {
        case .writes, .reads, .copiesTo, .binds, .aliases: 0
        case .owns, .observes, .injects: 1
        case .passes, .calls, .triggers, .sets, .derivesFrom: 2
        case .creates: 3
        }
    }

    private func appendPaths(
        kind: EdgeKind,
        slice: ContextSlice,
        nodes: [String: SemanticNode],
        to lines: inout [String]
    ) {
        let paths = slice.edges.filter { $0.kind == kind }
        if paths.isEmpty {
            lines.append("  none")
        } else {
            for edge in paths {
                lines.append("  \(nodes[edge.from]?.qualifiedName ?? edge.from) -> \(nodes[edge.to]?.qualifiedName ?? edge.to)")
            }
        }
    }
}
