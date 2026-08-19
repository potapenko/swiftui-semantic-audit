import AuditCore
import SemanticNormalization

public struct ArchitectureRule: ContextualAuditRule {
    public let identifier: RuleID

    public init(_ identifier: RuleID) {
        self.identifier = identifier
    }

    public func evaluate(graph: SemanticGraph, normalization: NormalizationResult) -> [AuditFinding] {
        evaluate(context: AuditRuleContext(graph: graph, normalization: normalization))
    }

    public func evaluate(context: AuditRuleContext) -> [AuditFinding] {
        let facts = ArchitectureFacts(context: context)
        switch identifier {
        case .modelAwareDescendant: return facts.modelAwareDescendants()
        case .multiOwnerComponent: return facts.multiOwnerComponents()
        case .crossFeatureOwnerDependency: return facts.crossFeatureDependencies()
        case .serviceOrRepositoryInView: return facts.serviceInputs()
        case .environmentCommandRouter: return facts.environmentCommandRouters()
        case .multiSourceBinding: return facts.multiSourceBindings()
        case .manualOwnerSynchronization: return facts.manualOwnerSynchronizations()
        case .hiddenCommandInLifecycle: return facts.lifecycleCommands()
        case .viewOwnedExternalEffect: return facts.viewOwnedEffects()
        case .imperativeFocusLifecycle: return facts.focusLifecycleWrites()
        case .selectionCorrectiveLoop: return facts.selectionLoops()
        case .geometryDrivenProductLayout: return facts.geometryLayouts()
        case .geometryEscapesLayoutBoundary: return facts.geometryEscapes()
        case .geometryTriggeredModelEffect: return facts.geometryEffects()
        case .manualPositioningAsLayout: return facts.manualPositioning()
        case .gestureButtonEmulation: return facts.gestureButtons()
        case .imperativePlatformViewUpdate: return facts.platformUpdates()
        case .directGlobalPlatformCommand: return facts.globalPlatformCommands()
        case .previewRequiresAppComposition: return facts.previewComposition()
        default: return []
        }
    }
}

private struct TypedBoundary {
    let view: SemanticNode
    let property: SemanticNode
    let type: SemanticNode
    let boundary: SemanticEdge
    let typedAs: SemanticEdge

    var edges: [SemanticEdge] { [boundary, typedAs] }
    var nodes: [String] { [view.id, property.id, type.id] }
}

private struct ConfiguredCall {
    let call: SemanticEdge
    let root: SemanticNode?
    let type: SemanticNode
    let support: [SemanticEdge]

    var nodes: [String] { [call.from, call.to, root?.id, type.id].compactMap { $0 } }
    var edges: [SemanticEdge] { [call] + support }
}

private struct ArchitectureFacts {
    private static let ownerRoles: Set<String> = [
        "application-model", "feature-model", "controller", "store", "presenter",
    ]
    private static let externalEffectRoles: Set<String> = [
        "repository", "service", "player", "dependency-bundle", "effect-sink",
    ]
    private static let lifecycleNames: Set<String> = ["onAppear", "onChange", "task"]
    private static let geometryLayoutNames: Set<String> = [
        "GeometryReader", "onGeometryChange", "coordinateSpace", "preference",
        "anchorPreference", "backgroundPreferenceValue", "overlayPreferenceValue", "offset", "position",
    ]

    let graph: SemanticGraph
    let normalization: NormalizationResult
    let index: GraphIndex

    init(context: AuditRuleContext) {
        self.graph = context.graph
        self.normalization = context.normalization
        self.index = context.index
    }

    func modelAwareDescendants() -> [AuditFinding] {
        views.flatMap { view -> [AuditFinding] in
            guard !isCompositionRoot(view) else { return [] }
            let boundaries = typedBoundaries(of: view).filter { hasRole($0.type, in: Self.ownerRoles) }
            guard Set(boundaries.map(\.type.id)).count == 1 else { return [] }
            return boundaries.map { boundary in
                finding(.modelAwareDescendant, .medium, .candidate, boundary.nodes, boundary.edges, ["focused-input"])
            }
        }
    }

    func multiOwnerComponents() -> [AuditFinding] {
        views.compactMap { view in
            guard !isCompositionRoot(view) else { return nil }
            let boundaries = typedBoundaries(of: view).filter {
                hasRole($0.type, in: Self.ownerRoles.union(Self.externalEffectRoles))
            }
            guard Set(boundaries.map(\.type.id)).count >= 2 else { return nil }
            return finding(
                .multiOwnerComponent,
                .high,
                .strongInference,
                [view.id] + boundaries.flatMap(\.nodes),
                boundaries.flatMap(\.edges),
                ["focused-input", "composition-root"]
            )
        }
    }

    func crossFeatureDependencies() -> [AuditFinding] {
        views.flatMap { view -> [AuditFinding] in
            guard let feature = view.feature else { return [] }
            return typedBoundaries(of: view).filter { boundary in
                guard let ownerFeature = boundary.type.feature else { return false }
                return ownerFeature != feature && hasRole(
                    boundary.type,
                    in: Self.ownerRoles.union(Self.externalEffectRoles)
                )
            }.map { boundary in
                finding(
                    .crossFeatureOwnerDependency,
                    .high,
                    .strongInference,
                    boundary.nodes,
                    boundary.edges,
                    ["feature-input"]
                )
            }
        }
    }

    func serviceInputs() -> [AuditFinding] {
        views.flatMap { view -> [AuditFinding] in
            guard !isCompositionRoot(view) else { return [] }
            return typedBoundaries(of: view).filter {
                hasRole($0.type, in: Self.externalEffectRoles)
            }.map { boundary in
                finding(
                    .serviceOrRepositoryInView,
                    .high,
                    .strongInference,
                    boundary.nodes,
                    boundary.edges,
                    ["action-closure", "focused-input"]
                )
            }
        }
    }

    func environmentCommandRouters() -> [AuditFinding] {
        views.flatMap { view -> [AuditFinding] in
            let actors = index.descendants(of: view.id)
            return typedBoundaries(of: view).filter { $0.boundary.kind == .injects }.compactMap { boundary in
                let memberLinks = index.edges(from: boundary.property.id, kind: .observes)
                let calls = memberLinks.flatMap { member in
                    index.edges(to: member.to, kind: .calls).filter { actors.contains($0.from) }
                }
                guard !calls.isEmpty else { return nil }
                return finding(
                    .environmentCommandRouter,
                    .medium,
                    .candidate,
                    boundary.nodes + calls.flatMap { [$0.from, $0.to] },
                    boundary.edges + memberLinks + calls,
                    ["action-closure", "focused-input"]
                )
            }
        }
    }

    func multiSourceBindings() -> [AuditFinding] {
        graph.nodes.filter {
            $0.kind == .binding && $0.evidence.contains { $0.kind == "binding-construction" }
        }.compactMap { binding in
            let actors = index.descendants(of: binding.id)
            let callTargets = Set(actors.flatMap { index.edges(from: $0, kind: .calls).map(\.to) })
            let rawSourceEdges = actors.sorted().flatMap { actor in
                (index.outgoing[actor] ?? []).filter { [.reads, .writes, .flowsTo].contains($0.kind) }
            }.filter { edge in
                guard edge.to != binding.id, let node = index.nodes[edge.to] else { return false }
                return !callTargets.contains(edge.to) &&
                    [.state, .binding, .observableState, .property, .input].contains(node.kind)
            }
            let memberRoots = Set(rawSourceEdges.flatMap { edge in
                index.edges(to: edge.to, kind: .observes).map(\.from)
            })
            let sourceEdges = rawSourceEdges.filter { !memberRoots.contains($0.to) }
            let sources = Set(sourceEdges.map { edge in
                normalization.valueByRepresentation[edge.to]?.id ?? edge.to
            })
            guard sources.count >= 2 else { return nil }
            return finding(
                .multiSourceBinding,
                .medium,
                .strongInference,
                [binding.id] + sourceEdges.flatMap { [$0.from, $0.to] },
                index.edges(from: binding.id, kind: .sets) + sourceEdges,
                ["focused-binding", "derived-value"]
            )
        }
    }

    func manualOwnerSynchronizations() -> [AuditFinding] {
        views.compactMap { view in
            guard !isCompositionRoot(view) else { return nil }
            let ownerRoots = Set(typedBoundaries(of: view).filter {
                hasRole($0.type, in: Self.ownerRoles)
            }.map(\.property.id))
            guard !ownerRoots.isEmpty else { return nil }
            let localStates = Set(index.ownedNodes(of: view.id, kind: .state).map(\.id))
            let lifecycle = lifecycleActors(in: view)
            var support: [SemanticEdge] = []
            var paths: Set<String> = []
            for copy in graph.edges where copy.kind == .copiesTo && localStates.contains(copy.to) {
                let observedRoot = index.edges(to: copy.from, kind: .observes).first?.from
                guard observedRoot.map(ownerRoots.contains) == true else { continue }
                for (lifecycleID, actors) in lifecycle where actors.contains(where: { actor in
                    index.edges(from: actor, kind: .writes).contains { $0.to == copy.to && overlaps($0, copy) }
                }) {
                    paths.insert(lifecycleID)
                    support.append(copy)
                }
            }
            guard paths.count >= 2 else { return nil }
            return finding(
                .manualOwnerSynchronization,
                .high,
                .strongInference,
                [view.id] + ownerRoots.sorted() + localStates.sorted(),
                support,
                ["Binding", "transactional-draft"]
            )
        }
    }

    func lifecycleCommands() -> [AuditFinding] {
        views.flatMap { view -> [AuditFinding] in
            guard !isCompositionRoot(view) else { return [] }
            return lifecycleActors(in: view).flatMap { lifecycle, actors in
                configuredCalls(from: actors).map { command in
                    finding(
                        .hiddenCommandInLifecycle,
                        .medium,
                        .candidate,
                        [view.id, lifecycle] + command.nodes,
                        command.edges,
                        ["explicit-event", "composition-root"]
                    )
                }
            }
        }
    }

    func viewOwnedEffects() -> [AuditFinding] {
        views.flatMap { view -> [AuditFinding] in
            guard !isCompositionRoot(view) else { return [] }
            let actors = index.descendants(of: view.id)
            let lifecycleActorIDs = Set(lifecycleActors(in: view).values.flatMap { $0 })
            return configuredCalls(from: actors.subtracting(lifecycleActorIDs)).filter {
                hasRole($0.type, in: Self.ownerRoles.union(Self.externalEffectRoles))
            }.map { command in
                finding(
                    .viewOwnedExternalEffect,
                    .high,
                    .candidate,
                    [view.id] + command.nodes,
                    command.edges,
                    ["action-closure", "composition-root"]
                )
            }
        }
    }

    func focusLifecycleWrites() -> [AuditFinding] {
        views.flatMap { view -> [AuditFinding] in
            let focus = Set(index.ownedNodes(of: view.id, kind: .state).filter {
                $0.evidence.contains { $0.kind == "property-wrapper:FocusState" }
            }.map(\.id))
            guard !focus.isEmpty else { return [] }
            return lifecycleActors(in: view).compactMap { lifecycle, actors in
                let writes = actors.flatMap { index.edges(from: $0, kind: .writes) }.filter {
                    focus.contains($0.to)
                }
                guard !writes.isEmpty else { return nil }
                return finding(
                    .imperativeFocusLifecycle,
                    .medium,
                    .strongInference,
                    [view.id, lifecycle] + focus.sorted(),
                    writes,
                    ["focus-binding", "user-action"]
                )
            }
        }
    }

    func selectionLoops() -> [AuditFinding] {
        views.compactMap { view in
            let candidates = Set(index.ownedNodes(of: view.id, kind: .state).filter { node in
                node.evidence.contains { $0.kind == "property-wrapper:FocusState" } ||
                    index.edges(from: node.id, kind: .typedAs).contains {
                        index.nodes[$0.to]?.qualifiedName == "SwiftUI.TextSelection"
                    }
            }.map(\.id))
            guard candidates.count >= 2 else { return nil }
            let copies = graph.edges.filter {
                $0.kind == .copiesTo && candidates.contains($0.from) && candidates.contains($0.to)
            }
            guard copies.count >= 2 else { return nil }
            return finding(
                .selectionCorrectiveLoop,
                .high,
                .strongInference,
                [view.id] + candidates.sorted(),
                copies,
                ["single-selection-owner", "focus-binding"]
            )
        }
    }

    func geometryLayouts() -> [AuditFinding] {
        geometryFlows(toNames: Self.geometryLayoutNames).map { source, target, edges in
            finding(
                .geometryDrivenProductLayout,
                .medium,
                .candidate,
                [source.id, target.id],
                edges,
                ["SwiftUI-layout"]
            )
        }
    }

    func geometryEscapes() -> [AuditFinding] {
        graph.edges.filter { edge in
            geometryValue(edge.from) && edge.kind == .passes && index.owner(of: edge.to)?.kind == .view
        }.map { edge in
            finding(
                .geometryEscapesLayoutBoundary,
                .medium,
                .strongInference,
                [edge.from, edge.to, index.owner(of: edge.to)?.id].compactMap { $0 },
                [edge],
                ["local-layout"]
            )
        }
    }

    func geometryEffects() -> [AuditFinding] {
        graph.edges.filter { $0.kind == .flowsTo && geometryValue($0.from) }.compactMap { flow in
            guard let call = graph.edges.first(where: { $0.kind == .calls && $0.to == flow.to }),
                  let configured = configuredCall(call)
            else { return nil }
            return finding(
                .geometryTriggeredModelEffect,
                .high,
                .strongInference,
                [flow.from] + configured.nodes,
                [flow] + configured.edges,
                ["explicit-pagination", "local-layout"]
            )
        }
    }

    func manualPositioning() -> [AuditFinding] {
        geometryFlows(toNames: ["offset", "position"]).map { source, target, edges in
            finding(
                .manualPositioningAsLayout,
                .medium,
                .candidate,
                [source.id, target.id],
                edges,
                ["SwiftUI-layout"]
            )
        }
    }

    func gestureButtons() -> [AuditFinding] {
        views.compactMap { view in
            let actors = index.descendants(of: view.id)
            let tap = generated(named: "onTapGesture", in: actors)
            let accessibility = generated(named: "accessibilityAddTraits", in: actors) +
                generated(named: "accessibilityAction", in: actors)
            guard !tap.isEmpty, !accessibility.isEmpty else { return nil }
            let nodes = tap + accessibility
            let creation = nodes.flatMap { index.edges(to: $0.id, kind: .creates) }
            return finding(
                .gestureButtonEmulation,
                .medium,
                .strongInference,
                [view.id] + nodes.map(\.id),
                creation,
                ["Button"]
            )
        }
    }

    func platformUpdates() -> [AuditFinding] {
        graph.nodes.filter {
            $0.kind == .function && ["updateNSView", "updateUIView"].contains($0.name)
        }.compactMap { function in
            let actors = index.descendants(of: function.id)
            let operations = actors.flatMap { index.outgoing[$0] ?? [] }.filter {
                [.writes, .calls, .flowsTo].contains($0.kind)
            }
            guard !operations.isEmpty else { return nil }
            return finding(
                .imperativePlatformViewUpdate,
                .high,
                .strongInference,
                [function.id] + operations.flatMap { [$0.from, $0.to] },
                operations,
                ["immutable-representable", "coordinator"]
            )
        }
    }

    func globalPlatformCommands() -> [AuditFinding] {
        views.flatMap { view -> [AuditFinding] in
            guard !isCompositionRoot(view) else { return [] }
            let actors = index.descendants(of: view.id)
            return graph.nodes.filter { node in
                actors.contains(node.id) && node.evidence.contains { $0.kind == "platform-command" }
            }.map { command in
                finding(
                    .directGlobalPlatformCommand,
                    .high,
                    .strongInference,
                    [view.id, command.id],
                    index.edges(to: command.id, kind: .creates),
                    ["environment-action", "platform-adapter"]
                )
            }
        }
    }

    func previewComposition() -> [AuditFinding] {
        graph.nodes.filter { $0.evidence.contains { $0.kind == "preview-composition" } }.compactMap { preview in
            let actors = index.descendants(of: preview.id)
            let calls = graph.edges.filter { edge in
                edge.kind == .calls && actors.contains(edge.from) && index.nodes[edge.to].map { target in
                    isCompositionRoot(target) || hasRole(
                        target,
                        in: Self.ownerRoles.union(Self.externalEffectRoles)
                    )
                } == true
            }
            guard !calls.isEmpty else { return nil }
            return finding(
                .previewRequiresAppComposition,
                .medium,
                .candidate,
                [preview.id] + calls.flatMap { [$0.from, $0.to] },
                calls,
                ["preview-fixture", "focused-input"]
            )
        }
    }

    private var views: [SemanticNode] {
        graph.nodes.filter { $0.kind == .view }.sorted { $0.id < $1.id }
    }

    private func typedBoundaries(of view: SemanticNode) -> [TypedBoundary] {
        let boundaryKinds: Set<EdgeKind> = [.owns, .binds, .observes, .injects]
        let candidates = (index.outgoing[view.id] ?? []).filter { boundaryKinds.contains($0.kind) }.flatMap {
            boundary -> [TypedBoundary] in
            guard let property = index.nodes[boundary.to] else { return [] }
            return index.edges(from: property.id, kind: .typedAs).compactMap { typedAs in
                guard let type = index.nodes[typedAs.to] else { return nil }
                return TypedBoundary(view: view, property: property, type: type, boundary: boundary, typedAs: typedAs)
            }
        }
        return Dictionary(grouping: candidates) { "\($0.property.id)|\($0.type.id)" }
            .values
            .compactMap { boundaries in
                boundaries.min {
                    (boundaryRank($0.boundary.kind), $0.boundary.id, $0.typedAs.id) <
                        (boundaryRank($1.boundary.kind), $1.boundary.id, $1.typedAs.id)
                }
            }
            .sorted { ($0.property.id, $0.type.id) < ($1.property.id, $1.type.id) }
    }

    private func configuredCalls(from actors: Set<String>) -> [ConfiguredCall] {
        graph.edges.filter { $0.kind == .calls && actors.contains($0.from) }
            .compactMap(configuredCall)
            .sorted { $0.call.id < $1.call.id }
    }

    private func configuredCall(_ call: SemanticEdge) -> ConfiguredCall? {
        if let target = index.nodes[call.to], !target.roles.isEmpty {
            return ConfiguredCall(call: call, root: nil, type: target, support: [])
        }
        for member in index.edges(to: call.to, kind: .observes) where sourceRangesOverlap(member, call) {
            guard let root = index.nodes[member.from],
                  let typedAs = index.edges(from: root.id, kind: .typedAs).first,
                  let type = index.nodes[typedAs.to],
                  !type.roles.isEmpty
            else { continue }
            return ConfiguredCall(call: call, root: root, type: type, support: [member, typedAs])
        }
        return nil
    }

    private func boundaryRank(_ kind: EdgeKind) -> Int {
        switch kind {
        case .injects: 0
        case .binds: 1
        case .observes: 2
        case .owns: 3
        default: 4
        }
    }

    private func sourceRangesOverlap(_ lhs: SemanticEdge, _ rhs: SemanticEdge) -> Bool {
        lhs.evidence.contains { left in
            rhs.evidence.contains { right in
                left.file == right.file &&
                    left.startLine <= right.endLine && right.startLine <= left.endLine
            }
        }
    }

    private func lifecycleActors(in view: SemanticNode) -> [String: Set<String>] {
        let viewActors = index.descendants(of: view.id)
        return Dictionary(uniqueKeysWithValues: graph.nodes.compactMap { node in
            guard viewActors.contains(node.id), Self.lifecycleNames.contains(baseName(node.name)) else { return nil }
            return (node.id, index.descendants(of: node.id))
        })
    }

    private func geometryFlows(toNames: Set<String>) -> [(SemanticNode, SemanticNode, [SemanticEdge])] {
        graph.edges.compactMap { edge in
            guard edge.kind == .flowsTo,
                  geometryValue(edge.from),
                  let source = index.nodes[edge.from],
                  let target = index.nodes[edge.to],
                  toNames.contains(baseName(target.name))
            else { return nil }
            return (source, target, [edge])
        }
    }

    private func geometryValue(_ id: String) -> Bool {
        guard let node = index.nodes[id] else { return false }
        if node.evidence.contains(where: { $0.kind == "geometry-proxy" }) { return true }
        return index.edges(to: id, kind: .observes).contains { edge in
            index.nodes[edge.from]?.evidence.contains { $0.kind == "geometry-proxy" } == true
        }
    }

    private func generated(named name: String, in actors: Set<String>) -> [SemanticNode] {
        graph.nodes.filter { actors.contains($0.id) && baseName($0.name) == name }
    }

    private func hasRole(_ node: SemanticNode, in roles: Set<String>) -> Bool {
        !roles.isDisjoint(with: node.roles)
    }

    private func isCompositionRoot(_ node: SemanticNode) -> Bool {
        node.roles.contains("composition-root")
    }

    private func baseName(_ name: String) -> String {
        name.split(separator: "#").first.map(String.init) ?? name
    }

    private func overlaps(_ lhs: SemanticEdge, _ rhs: SemanticEdge) -> Bool {
        !Set(lhs.evidence).isDisjoint(with: rhs.evidence)
    }

    private func finding(
        _ rule: RuleID,
        _ severity: Severity,
        _ confidence: Confidence,
        _ nodes: [String],
        _ edges: [SemanticEdge],
        _ patterns: [String]
    ) -> AuditFinding {
        let canonicalEdges = Dictionary(grouping: edges, by: \.id).values.compactMap(\.first).sorted { $0.id < $1.id }
        return AuditFinding(
            rule: rule,
            severity: severity,
            confidence: confidence,
            nodes: nodes,
            edges: canonicalEdges.map(\.id),
            evidence: evidence(from: canonicalEdges),
            suggestedPatterns: patterns
        )
    }
}

func applyFindingDominance(_ findings: [AuditFinding]) -> [AuditFinding] {
    let specificByRule = Dictionary(grouping: findings, by: \.rule)
    return findings.filter { finding in
        let nodes = Set(finding.nodes)
        switch finding.rule {
        case .broadObservableInput:
            return !(specificByRule[.modelAwareDescendant] ?? []).contains {
                !nodes.isDisjoint(with: $0.nodes)
            }
        case .modelAwareDescendant:
            return !(specificByRule[.multiOwnerComponent] ?? []).contains {
                !nodes.isDisjoint(with: $0.nodes)
            }
        case .viewOwnedExternalEffect:
            return !(specificByRule[.hiddenCommandInLifecycle] ?? []).contains {
                !Set(finding.edges).isDisjoint(with: $0.edges)
            }
        case .geometryDrivenProductLayout:
            return ![RuleID.geometryEscapesLayoutBoundary, .geometryTriggeredModelEffect, .manualPositioningAsLayout]
                .flatMap { specificByRule[$0] ?? [] }
                .contains { !Set(finding.edges).isDisjoint(with: $0.edges) }
        default:
            return true
        }
    }
}
