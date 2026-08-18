import AuditCore
import SemanticNormalization

public struct CommandShapedBindingRule: AuditRule {
    public let identifier: RuleID = .commandShapedBinding
    public init() {}

    public func evaluate(graph: SemanticGraph, normalization: NormalizationResult) -> [AuditFinding] {
        let index = GraphIndex(graph)
        return graph.nodes.filter {
            $0.kind == .binding && $0.evidence.contains { $0.kind == "binding-construction" }
        }.compactMap { binding in
            guard let setterEdge = index.edges(from: binding.id, kind: .sets).first,
                  let setter = index.nodes[setterEdge.to]
            else { return nil }
            let actors = index.descendants(of: setter.id)
            let writes = actors.sorted().flatMap { index.edges(from: $0, kind: .writes) }
            let commands = actors.sorted().flatMap { index.edges(from: $0, kind: .calls) }.filter { edge in
                !edge.evidence.contains { $0.kind == "assignment-transform-call" }
            }
            guard !commands.isEmpty else { return nil }
            let creation = index.edges(to: binding.id, kind: .creates).filter {
                $0.evidence.contains { $0.kind == "binding-construction" }
            }
            let supporting = creation + [setterEdge] + writes + commands
            return AuditFinding(
                rule: identifier,
                severity: .medium,
                confidence: .strongInference,
                nodes: [binding.id, setter.id] + supporting.flatMap { [$0.from, $0.to] },
                edges: supporting.map(\.id),
                evidence: evidence(from: supporting),
                suggestedPatterns: ["action-closure", "focused-binding"]
            )
        }
    }
}

public struct BindingFactoryRule: AuditRule {
    public let identifier: RuleID = .bindingFactory
    public init() {}

    public func evaluate(graph: SemanticGraph, normalization: NormalizationResult) -> [AuditFinding] {
        let index = GraphIndex(graph)
        return graph.nodes.filter {
            $0.kind == .binding && $0.evidence.contains { $0.kind == "binding-factory" }
        }.map { binding in
            let creation = index.edges(to: binding.id, kind: .creates).filter {
                $0.evidence.contains { $0.kind == "binding-construction" }
            }
            let setter = index.edges(from: binding.id, kind: .sets)
            let supporting = creation + setter
            return AuditFinding(
                rule: identifier,
                severity: .medium,
                confidence: .candidate,
                nodes: [binding.id] + supporting.flatMap { [$0.from, $0.to] },
                edges: supporting.map(\.id),
                evidence: Array(Set(binding.evidence + evidence(from: supporting))).sorted(by: Evidence.canonicalOrder),
                suggestedPatterns: ["action-closure", "focused-binding"]
            )
        }
    }
}

public struct ObservableModelTunnelRule: AuditRule {
    public let identifier: RuleID = .observableModelTunnel
    public init() {}

    public func evaluate(graph: SemanticGraph, normalization: NormalizationResult) -> [AuditFinding] {
        let index = GraphIndex(graph)
        var findings: [AuditFinding] = []
        for value in normalization.semanticValues {
            let representations = Set(value.representations)
            let passes = graph.edges.filter { edge in
                edge.kind == .passes && representations.contains(edge.from) && representations.contains(edge.to) &&
                    index.nodes[edge.to]?.kind == .observableState && index.owner(of: edge.to)?.kind == .view
            }
            let incomingTargets = Set(passes.map(\.to))
            let starts = passes.filter { !incomingTargets.contains($0.from) }.sorted { $0.id < $1.id }
            for start in starts {
                for path in passPaths(from: start, passes: passes, visited: [start.from, start.to])
                    where path.count >= 2 {
                    let terminal = path.last!.to
                    guard !passes.contains(where: { $0.from == terminal }) else { continue }
                    let pathNodes = [path[0].from] + path.map(\.to)
                    let owners = pathNodes.compactMap { index.owner(of: $0)?.id }
                    findings.append(AuditFinding(
                        rule: identifier,
                        severity: .medium,
                        confidence: .strongInference,
                        nodes: pathNodes + owners,
                        edges: path.map(\.id),
                        evidence: evidence(from: path),
                        suggestedPatterns: ["action-closure", "focused-binding", "focused-input"],
                        depth: path.count,
                        discriminator: "depth:\(path.count)|\(path[0].from)|\(terminal)"
                    ))
                }
            }
        }
        return findings
    }

    private func passPaths(
        from edge: SemanticEdge,
        passes: [SemanticEdge],
        visited: Set<String>
    ) -> [[SemanticEdge]] {
        let next = passes.filter { $0.from == edge.to && !visited.contains($0.to) }.sorted { $0.id < $1.id }
        if next.isEmpty { return [[edge]] }
        return next.flatMap { successor in
            var nextVisited = visited
            nextVisited.insert(successor.to)
            return passPaths(from: successor, passes: passes, visited: nextVisited).map { [edge] + $0 }
        }
    }
}

public struct BroadObservableInputRule: AuditRule {
    public let identifier: RuleID = .broadObservableInput
    public init() {}

    public func evaluate(graph: SemanticGraph, normalization: NormalizationResult) -> [AuditFinding] {
        let index = GraphIndex(graph)
        let mirroredObservableMembers = Set(index.identityPairs().flatMap(\.nodes).filter(index.isObservableMember))
        var findings: [AuditFinding] = []
        for view in graph.nodes.filter({ $0.kind == .view }).sorted(by: { $0.id < $1.id }) {
            let actors = index.descendants(of: view.id)
            let boundaryEdges = (index.edges(from: view.id, kind: .observes) +
                index.edges(from: view.id, kind: .injects)).filter { edge in
                guard let root = index.nodes[edge.to] else { return false }
                return [.observableState, .input].contains(root.kind) &&
                    root.evidence.contains { $0.kind == "property-wrapper" }
            }
            for boundary in boundaryEdges {
                let memberEdges = index.edges(from: boundary.to, kind: .observes).filter {
                    $0.evidence.contains { $0.kind == "observable-member" }
                }
                guard memberEdges.allSatisfy({ !mirroredObservableMembers.contains($0.to) }) else { continue }
                var uses: [SemanticEdge] = []
                var projectionCreation: [SemanticEdge] = []
                for member in memberEdges {
                    uses += graph.edges.filter { edge in
                        actors.contains(edge.from) && edge.to == member.to &&
                            [.reads, .writes, .calls].contains(edge.kind)
                    }
                    let projections = index.edges(to: member.to, kind: .aliases).filter { edge in
                        index.nodes[edge.from]?.kind == .binding
                    }
                    for projection in projections {
                        let creators = index.edges(to: projection.from, kind: .creates).filter {
                            actors.contains($0.from)
                        }
                        if !creators.isEmpty {
                            uses.append(projection)
                            projectionCreation += creators
                        }
                    }
                }
                guard !uses.isEmpty else { continue }
                let usedMembers = Set(uses.map(\.to))
                let observed = memberEdges.filter { usedMembers.contains($0.to) }
                let supporting = [boundary] + observed + uses + projectionCreation
                findings.append(AuditFinding(
                    rule: identifier,
                    severity: .medium,
                    confidence: .candidate,
                    nodes: [view.id, boundary.to] + supporting.flatMap { [$0.from, $0.to] },
                    edges: supporting.map(\.id),
                    evidence: evidence(from: supporting),
                    suggestedPatterns: ["action-closure", "focused-binding", "focused-input"]
                ))
            }
        }
        return findings
    }
}
