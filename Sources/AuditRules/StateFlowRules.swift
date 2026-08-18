import AuditCore
import SemanticNormalization

public struct MirroredStateRule: AuditRule {
    public let identifier: RuleID = .mirroredState
    public init() {}

    public func evaluate(graph: SemanticGraph, normalization: NormalizationResult) -> [AuditFinding] {
        let index = GraphIndex(graph)
        return index.identityPairs().compactMap { pair in
            let stateIDs = pair.nodes.filter { index.nodes[$0]?.kind == .state }
            guard stateIDs.count == 1,
                  !pair.nodes.contains(where: index.isObservableMember),
                  normalization.valueByRepresentation[pair.lhs]?.classification == nil
            else { return nil }
            return AuditFinding(
                rule: identifier,
                severity: .high,
                confidence: .strongInference,
                nodes: pair.nodes,
                edges: pair.edges.map(\.id),
                evidence: evidence(from: pair.edges),
                suggestedPatterns: ["Binding"]
            )
        }
    }
}

public struct ManualTwoWaySyncRule: AuditRule {
    public let identifier: RuleID = .manualTwoWaySync
    public init() {}

    public func evaluate(graph: SemanticGraph, normalization: NormalizationResult) -> [AuditFinding] {
        let index = GraphIndex(graph)
        return index.identityPairs().compactMap { pair in
            guard pair.nodes.allSatisfy(index.isMutableRepresentation),
                  !pair.nodes.contains(where: index.isObservableMember),
                  normalization.valueByRepresentation[pair.lhs]?.classification == nil
            else { return nil }
            return AuditFinding(
                rule: identifier,
                severity: .high,
                confidence: .strongInference,
                nodes: pair.nodes,
                edges: pair.edges.map(\.id),
                evidence: evidence(from: pair.edges),
                suggestedPatterns: ["Binding"]
            )
        }
    }
}

public struct ObservableStateMirrorRule: AuditRule {
    public let identifier: RuleID = .observableStateMirror
    public init() {}

    public func evaluate(graph: SemanticGraph, normalization: NormalizationResult) -> [AuditFinding] {
        let index = GraphIndex(graph)
        return index.identityPairs().compactMap { pair in
            let stateIDs = pair.nodes.filter { index.nodes[$0]?.kind == .state }
            let observableIDs = pair.nodes.filter(index.isObservableMember)
            guard stateIDs.count == 1, observableIDs.count == 1,
                  normalization.valueByRepresentation[pair.lhs]?.classification == nil
            else { return nil }
            let observableEdges = observableIDs.flatMap { index.edges(to: $0, kind: .observes) }
            let allEdges = pair.edges + observableEdges
            return AuditFinding(
                rule: identifier,
                severity: .high,
                confidence: .strongInference,
                nodes: pair.nodes + observableEdges.map(\.from),
                edges: allEdges.map(\.id),
                evidence: evidence(from: allEdges),
                suggestedPatterns: ["Bindable", "Binding"]
            )
        }
    }
}

public struct StoredDerivedStateRule: AuditRule {
    public let identifier: RuleID = .storedDerivedState
    public init() {}

    public func evaluate(graph: SemanticGraph, normalization: NormalizationResult) -> [AuditFinding] {
        let index = GraphIndex(graph)
        return graph.nodes.filter { $0.kind == .state }.compactMap { state in
            let derivations = index.edges(from: state.id, kind: .derivesFrom)
            let inputs = Set(derivations.map(\.to))
            guard !inputs.isEmpty,
                  !inputs.contains(where: { input in
                      index.edges(from: input, kind: .derivesFrom).contains { $0.to == state.id }
                  })
            else { return nil }
            return AuditFinding(
                rule: identifier,
                severity: .medium,
                confidence: .strongInference,
                nodes: [state.id] + inputs.sorted(),
                edges: derivations.map(\.id),
                evidence: evidence(from: derivations),
                suggestedPatterns: ["derived-value"]
            )
        }
    }
}

public struct ValueSetterPairRule: AuditRule {
    public let identifier: RuleID = .valueSetterPair
    public init() {}

    public func evaluate(graph: SemanticGraph, normalization: NormalizationResult) -> [AuditFinding] {
        let index = GraphIndex(graph)
        var findings: [AuditFinding] = []
        for view in graph.nodes.filter({ $0.kind == .view }).sorted(by: { $0.id < $1.id }) {
            let callbacks = index.ownedNodes(of: view.id, kind: .callback)
            let values = index.ownedNodes(of: view.id).filter {
                $0.kind == .property || $0.kind == .input
            }
            for callback in callbacks {
                for value in values {
                    guard let qualifyingCall = qualifyingCall(
                        to: callback.id,
                        using: value.id,
                        index: index,
                        normalization: normalization
                    ) else { continue }
                    let valuePasses = index.edges(to: value.id, kind: .passes)
                    let callbackPasses = index.edges(to: callback.id, kind: .passes).filter {
                        index.nodes[$0.from]?.kind == .closure
                    }
                    for valuePass in valuePasses {
                        for callbackPass in callbackPasses {
                            let setterActors = index.descendants(of: callbackPass.from)
                            guard let setterWrite = setterActors.sorted().flatMap({ index.edges(from: $0, kind: .writes) })
                                .first(where: { $0.to == valuePass.from })
                            else { continue }
                            let supportingEdges = [
                                valuePass,
                                callbackPass,
                                setterWrite,
                                qualifyingCall.call,
                                qualifyingCall.identitySupport,
                            ]
                            findings.append(AuditFinding(
                                rule: identifier,
                                severity: .medium,
                                confidence: .strongInference,
                                nodes: [view.id, value.id, callback.id, valuePass.from, callbackPass.from],
                                edges: supportingEdges.map(\.id),
                                evidence: evidence(from: supportingEdges),
                                suggestedPatterns: ["Binding"]
                            ))
                        }
                    }
                }
            }
        }
        return findings
    }

    private func qualifyingCall(
        to callback: String,
        using value: String,
        index: GraphIndex,
        normalization: NormalizationResult
    ) -> (call: SemanticEdge, identitySupport: SemanticEdge)? {
        guard let semanticValue = normalization.valueByRepresentation[value]?.id else { return nil }
        for call in index.edges(to: callback, kind: .calls) {
            for event in index.edges(to: call.from, kind: .creates).map(\.from).sorted() {
                if let trigger = index.edges(to: event, kind: .triggers).first(where: {
                    normalization.valueByRepresentation[$0.from]?.id == semanticValue
                }) {
                    return (call, trigger)
                }
            }
        }
        return nil
    }
}

public struct CallbackBindingTunnelRule: AuditRule {
    public let identifier: RuleID = .callbackBindingTunnel
    public init() {}

    public func evaluate(graph: SemanticGraph, normalization: NormalizationResult) -> [AuditFinding] {
        let index = GraphIndex(graph)
        var findings: [AuditFinding] = []
        let starts = graph.edges.filter {
            $0.kind == .passes && index.nodes[$0.from]?.kind == .closure && index.nodes[$0.to]?.kind == .callback
        }.sorted { $0.id < $1.id }
        for start in starts {
            let paths = callbackPaths(from: start.to, index: index, visited: [start.to])
            for path in paths where path.nodes.count >= 3 {
                guard index.edges(from: path.nodes.last!, kind: .passes).allSatisfy({ index.nodes[$0.to]?.kind != .callback }),
                      let support = identitySupport(
                          startClosure: start.from,
                          callbacks: path.nodes,
                          index: index,
                          normalization: normalization
                      )
                else { continue }
                let allEdges = [start] + path.edges + support.edges
                let ownerNodes = path.nodes.compactMap { index.owner(of: $0)?.id }
                findings.append(AuditFinding(
                    rule: identifier,
                    severity: .medium,
                    confidence: .strongInference,
                    nodes: [start.from] + path.nodes + ownerNodes,
                    edges: allEdges.map(\.id),
                    evidence: evidence(from: Array(allEdges)),
                    suggestedPatterns: ["Binding"],
                    depth: path.nodes.count,
                    discriminator: "depth:\(path.nodes.count)"
                ))
            }
        }
        return findings
    }

    private func identitySupport(
        startClosure: String,
        callbacks: [String],
        index: GraphIndex,
        normalization: NormalizationResult
    ) -> TunnelIdentitySupport? {
        guard let terminal = callbacks.last else { return nil }
        for write in index.edges(from: startClosure, kind: .writes) {
            guard let value = normalization.valueByRepresentation[write.to] else { continue }
            var valuePasses: [SemanticEdge] = []
            var validOwners = true
            for callback in callbacks {
                guard let owner = index.owner(of: callback),
                      let pass = index.ownedNodes(of: owner.id).compactMap({ representation -> SemanticEdge? in
                          guard representation.kind != .callback,
                                normalization.valueByRepresentation[representation.id]?.id == value.id
                          else { return nil }
                          return index.edges(to: representation.id, kind: .passes).first
                      }).first
                else {
                    validOwners = false
                    break
                }
                valuePasses.append(pass)
            }
            guard validOwners else { continue }

            for call in index.edges(to: terminal, kind: .calls) {
                let directRead = index.edges(from: call.from, kind: .reads).first {
                    normalization.valueByRepresentation[$0.to]?.id == value.id
                }
                let creatorEvents = index.edges(to: call.from, kind: .creates).map(\.from)
                let trigger = creatorEvents.compactMap { event in
                    index.edges(to: event, kind: .triggers).first {
                        normalization.valueByRepresentation[$0.from]?.id == value.id
                    }
                }.first
                if directRead != nil || trigger != nil {
                    return TunnelIdentitySupport(
                        edges: [write, call] + valuePasses + [directRead, trigger].compactMap { $0 }
                    )
                }
            }
        }
        return nil
    }

    private func callbackPaths(from callback: String, index: GraphIndex, visited: Set<String>) -> [CallbackPath] {
        let nextEdges = index.edges(from: callback, kind: .passes).filter {
            index.nodes[$0.to]?.kind == .callback && !visited.contains($0.to)
        }
        if nextEdges.isEmpty { return [CallbackPath(nodes: [callback], edges: [])] }
        var paths: [CallbackPath] = []
        for edge in nextEdges {
            var nextVisited = visited
            nextVisited.insert(edge.to)
            for suffix in callbackPaths(from: edge.to, index: index, visited: nextVisited) {
                paths.append(CallbackPath(nodes: [callback] + suffix.nodes, edges: [edge] + suffix.edges))
            }
        }
        return paths
    }
}

private struct CallbackPath {
    let nodes: [String]
    let edges: [SemanticEdge]
}

private struct TunnelIdentitySupport {
    let edges: [SemanticEdge]
}
