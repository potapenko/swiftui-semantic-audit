import AuditCore
import Dispatch
import Foundation
import SemanticNormalization

public protocol AuditRule: Sendable {
    var identifier: RuleID { get }
    func evaluate(graph: SemanticGraph, normalization: NormalizationResult) -> [AuditFinding]
}

public protocol ContextualAuditRule: AuditRule {
    func evaluate(context: AuditRuleContext) -> [AuditFinding]
}

public struct AuditRuleContext: Sendable {
    public let graph: SemanticGraph
    public let normalization: NormalizationResult
    let index: GraphIndex

    public init(graph: SemanticGraph, normalization: NormalizationResult) {
        self.graph = graph
        self.normalization = normalization
        self.index = GraphIndex(graph)
    }
}

public struct AuditEngine: Sendable {
    private let rules: [any AuditRule]
    private let maximumParallelism: Int

    public init(rules: [any AuditRule] = [
        MirroredStateRule(),
        ManualTwoWaySyncRule(),
        ValueSetterPairRule(),
        CallbackBindingTunnelRule(),
        ObservableStateMirrorRule(),
        StoredDerivedStateRule(),
        CommandShapedBindingRule(),
        BindingFactoryRule(),
        ObservableModelTunnelRule(),
        BroadObservableInputRule(),
        ArchitectureRule(.modelAwareDescendant),
        ArchitectureRule(.multiOwnerComponent),
        ArchitectureRule(.crossFeatureOwnerDependency),
        ArchitectureRule(.serviceOrRepositoryInView),
        ArchitectureRule(.environmentCommandRouter),
        ArchitectureRule(.multiSourceBinding),
        ArchitectureRule(.manualOwnerSynchronization),
        ArchitectureRule(.hiddenCommandInLifecycle),
        ArchitectureRule(.viewOwnedExternalEffect),
        ArchitectureRule(.imperativeFocusLifecycle),
        ArchitectureRule(.selectionCorrectiveLoop),
        ArchitectureRule(.geometryDrivenProductLayout),
        ArchitectureRule(.geometryEscapesLayoutBoundary),
        ArchitectureRule(.geometryTriggeredModelEffect),
        ArchitectureRule(.manualPositioningAsLayout),
        ArchitectureRule(.gestureButtonEmulation),
        ArchitectureRule(.imperativePlatformViewUpdate),
        ArchitectureRule(.directGlobalPlatformCommand),
        ArchitectureRule(.previewRequiresAppComposition),
    ], maximumParallelism: Int = ProcessInfo.processInfo.activeProcessorCount) {
        self.rules = rules
        self.maximumParallelism = max(1, maximumParallelism)
    }

    public func audit(graph: SemanticGraph) -> AuditReport {
        let normalization = SemanticNormalizer().normalize(graph)
        let context = AuditRuleContext(graph: graph, normalization: normalization)
        let results = RuleResultCollector(count: rules.count)
        let workerCount = min(maximumParallelism, rules.count)
        if workerCount > 1 {
            DispatchQueue.concurrentPerform(iterations: workerCount) { workerIndex in
                for index in stride(from: workerIndex, to: rules.count, by: workerCount) {
                    results.store(evaluate(rules[index], context: context), at: index)
                }
            }
        } else {
            for (index, rule) in rules.enumerated() {
                results.store(evaluate(rule, context: context), at: index)
            }
        }
        var findingsByID: [String: AuditFinding] = [:]
        for finding in results.flattened() {
            findingsByID[finding.id] = finding
        }
        let findings = applyFindingDominance(Array(findingsByID.values)).sorted {
            ($0.rule.rawValue, $0.id) < ($1.rule.rawValue, $1.id)
        }
        let index = GraphIndex(graph)
        let mutableValues = normalization.semanticValues.filter { value in
            value.representations.contains { id in
                guard let node = index.nodes[id] else { return false }
                return [.state, .binding, .observableState].contains(node.kind)
            }
        }
        let duplicatedValues = mutableValues.filter { value in
            guard value.classification == nil else { return false }
            return LogicalSourceCounter.count(for: value, in: graph) > 1
        }
        let manualFindings = findings.filter { $0.rule == .manualTwoWaySync }
        let metrics = AuditMetrics(
            mutableSemanticValues: mutableValues.count,
            stateRepresentations: graph.nodes.filter { $0.kind == .state }.count,
            bindingEdges: graph.edges.filter { $0.kind == .binds }.count,
            manualSynchronizationEdges: manualFindings.reduce(0) { count, finding in
                count + finding.edges.filter { index.edges[$0]?.kind == .copiesTo }.count
            },
            callbackTunnels: findings.filter { $0.rule == .callbackBindingTunnel }.count,
            derivedMutableValues: findings.filter { $0.rule == .storedDerivedState }.count,
            duplicatedSourcesOfTruth: duplicatedValues.count,
            ownershipViolations: findings.filter {
                $0.rule == .mirroredState || $0.rule == .observableStateMirror
            }.count
        )
        return AuditReport(
            resolution: graph.resolution,
            configurationDigest: graph.configurationDigest,
            metrics: metrics,
            semanticValues: normalization.semanticValues,
            findings: findings
        )
    }

    private func evaluate(_ rule: any AuditRule, context: AuditRuleContext) -> [AuditFinding] {
        if let contextual = rule as? any ContextualAuditRule {
            return contextual.evaluate(context: context)
        }
        return rule.evaluate(graph: context.graph, normalization: context.normalization)
    }
}

private final class RuleResultCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var values: [[AuditFinding]?]

    init(count: Int) {
        values = Array(repeating: nil, count: count)
    }

    func store(_ findings: [AuditFinding], at index: Int) {
        lock.lock()
        values[index] = findings
        lock.unlock()
    }

    func flattened() -> [AuditFinding] {
        lock.lock()
        defer { lock.unlock() }
        return values.compactMap { $0 }.flatMap { $0 }
    }
}

struct GraphIndex: Sendable {
    let graph: SemanticGraph
    let nodes: [String: SemanticNode]
    let edges: [String: SemanticEdge]
    let outgoing: [String: [SemanticEdge]]
    let incoming: [String: [SemanticEdge]]

    init(_ graph: SemanticGraph) {
        self.graph = graph
        self.nodes = Dictionary(uniqueKeysWithValues: graph.nodes.map { ($0.id, $0) })
        self.edges = Dictionary(uniqueKeysWithValues: graph.edges.map { ($0.id, $0) })
        self.outgoing = Dictionary(grouping: graph.edges, by: \.from)
            .mapValues { $0.sorted { $0.id < $1.id } }
        self.incoming = Dictionary(grouping: graph.edges, by: \.to)
            .mapValues { $0.sorted { $0.id < $1.id } }
    }

    func edges(from: String, kind: EdgeKind) -> [SemanticEdge] {
        (outgoing[from] ?? []).filter { $0.kind == kind }
    }

    func edges(to: String, kind: EdgeKind) -> [SemanticEdge] {
        (incoming[to] ?? []).filter { $0.kind == kind }
    }

    func ownedNodes(of owner: String, kind: NodeKind? = nil) -> [SemanticNode] {
        edges(from: owner, kind: .owns).compactMap { nodes[$0.to] }.filter { node in
            kind == nil || node.kind == kind
        }.sorted { $0.id < $1.id }
    }

    func owner(of node: String) -> SemanticNode? {
        let ownershipKinds: Set<EdgeKind> = [.owns, .binds, .injects, .observes]
        return (incoming[node] ?? []).first(where: { edge in
            ownershipKinds.contains(edge.kind) && nodes[edge.from].map {
                $0.kind == .view || $0.kind == .type
            } == true
        }).flatMap { nodes[$0.from] }
    }

    func descendants(of root: String, through kind: EdgeKind = .creates, limit: Int = 256) -> Set<String> {
        var visited: Set<String> = [root]
        var queue = [root]
        while let current = queue.first, visited.count < limit {
            queue.removeFirst()
            for edge in edges(from: current, kind: kind) where visited.insert(edge.to).inserted {
                queue.append(edge.to)
            }
        }
        return visited
    }

    func isObservableMember(_ id: String) -> Bool {
        edges(to: id, kind: .observes).contains { edge in
            guard let source = nodes[edge.from] else { return false }
            return source.kind == .input || source.kind == .observableState
        }
    }

    func isMutableRepresentation(_ id: String) -> Bool {
        guard let node = nodes[id] else { return false }
        if [.state, .binding, .observableState].contains(node.kind) { return true }
        return edges(to: id, kind: .writes).isEmpty == false
    }

    func hasBindingRepresentation(_ ids: [String]) -> Bool {
        ids.contains { nodes[$0]?.kind == .binding }
    }

    func identityPairs() -> [IdentityPair] {
        let copies = graph.edges.filter {
            $0.kind == .copiesTo && $0.evidence.contains { $0.kind == "assignment" }
        }
        let byDirection = Dictionary(grouping: copies) { "\($0.from)|\($0.to)" }
        var emitted: Set<String> = []
        var result: [IdentityPair] = []
        for edge in copies.sorted(by: { $0.id < $1.id }) {
            guard edge.from != edge.to else { continue }
            let ordered = [edge.from, edge.to].sorted()
            let key = ordered.joined(separator: "|")
            guard emitted.insert(key).inserted,
                  let forward = byDirection["\(ordered[0])|\(ordered[1])"]?.first,
                  let reverse = byDirection["\(ordered[1])|\(ordered[0])"]?.first,
                  forward.id != reverse.id
            else { continue }
            result.append(IdentityPair(lhs: ordered[0], rhs: ordered[1], forward: forward, reverse: reverse))
        }
        return result
    }
}

struct IdentityPair {
    let lhs: String
    let rhs: String
    let forward: SemanticEdge
    let reverse: SemanticEdge

    var nodes: [String] { [lhs, rhs] }
    var edges: [SemanticEdge] { [forward, reverse] }
}

func evidence(from edges: [SemanticEdge]) -> [Evidence] {
    Array(Set(edges.flatMap(\.evidence))).sorted(by: Evidence.canonicalOrder)
}
