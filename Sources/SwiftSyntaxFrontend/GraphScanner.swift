import AuditCore
import Foundation
import SwiftParser
import SwiftSyntax
import SwiftUISemantics

public enum GraphScannerError: Error, CustomStringConvertible {
    case inputDoesNotExist(String)
    case noSwiftFiles(String)
    case unreadableFile(String, Error)
    case stableIdentityCollision([String])

    public var description: String {
        switch self {
        case .inputDoesNotExist(let path): "input does not exist: \(path)"
        case .noSwiftFiles(let path): "no Swift source files found under: \(path)"
        case .unreadableFile(let path, let error): "cannot read \(path): \(error.localizedDescription)"
        case .stableIdentityCollision(let identities):
            "stable identity collision: \(identities.sorted().joined(separator: ", "))"
        }
    }
}

public struct GraphScanner: Sendable {
    public init() {}

    public func scan(path: String) throws -> SemanticGraph {
        let fileManager = FileManager.default
        let requestedURL = URL(fileURLWithPath: path)
        let rootURL = requestedURL.standardizedFileURL.resolvingSymlinksInPath()

        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: rootURL.path, isDirectory: &isDirectory) else {
            throw GraphScannerError.inputDoesNotExist(path)
        }

        let sourceURLs = try swiftFiles(at: rootURL, isDirectory: isDirectory.boolValue)
        guard !sourceURLs.isEmpty else { throw GraphScannerError.noSwiftFiles(path) }

        let moduleName = isDirectory.boolValue
            ? rootURL.lastPathComponent
            : rootURL.deletingPathExtension().lastPathComponent
        let builder = GraphBuilder(moduleName: moduleName)
        let moduleEvidence = Evidence(file: ".", startLine: 1, endLine: 1, kind: "module-root")
        builder.addNode(kind: .module, name: moduleName, qualifiedName: moduleName, evidence: moduleEvidence)

        var parsed: [(tree: SourceFileSyntax, relativePath: String)] = []
        for sourceURL in sourceURLs {
            let relativePath = relativePath(for: sourceURL, root: rootURL, rootIsDirectory: isDirectory.boolValue)
            do {
                let source = try String(contentsOf: sourceURL, encoding: .utf8)
                parsed.append((Parser.parse(source: source), relativePath))
            } catch {
                throw GraphScannerError.unreadableFile(relativePath, error)
            }
        }

        for item in parsed {
            let converter = SourceLocationConverter(fileName: item.relativePath, tree: item.tree)
            DeclarationVisitor(
                builder: builder,
                file: item.relativePath,
                converter: converter,
                predeclareOnly: true
            ).walk(item.tree)
        }
        for item in parsed {
            let converter = SourceLocationConverter(fileName: item.relativePath, tree: item.tree)
            DeclarationVisitor(builder: builder, file: item.relativePath, converter: converter).walk(item.tree)
        }
        for item in parsed {
            let converter = SourceLocationConverter(fileName: item.relativePath, tree: item.tree)
            RelationshipVisitor(builder: builder, file: item.relativePath, converter: converter).walk(item.tree)
        }

        return try builder.graph()
    }

    private func swiftFiles(at root: URL, isDirectory: Bool) throws -> [URL] {
        if !isDirectory {
            return root.pathExtension.lowercased() == "swift" ? [root] : []
        }
        let keys: [URLResourceKey] = [.isRegularFileKey, .isDirectoryKey]
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else { return [] }

        var files: [URL] = []
        for case let url as URL in enumerator {
            if url.pathExtension.lowercased() == "swift",
               (try? url.resourceValues(forKeys: Set(keys)).isRegularFile) == true {
                files.append(url.standardizedFileURL)
            }
        }
        return files.sorted { $0.path < $1.path }
    }

    private func relativePath(for file: URL, root: URL, rootIsDirectory: Bool) -> String {
        guard rootIsDirectory else { return file.lastPathComponent }
        let prefix = root.path.hasSuffix("/") ? root.path : root.path + "/"
        let relative = file.path.hasPrefix(prefix) ? String(file.path.dropFirst(prefix.count)) : file.lastPathComponent
        return relative.replacingOccurrences(of: "\\", with: "/")
    }
}

private final class GraphBuilder {
    let moduleName: String
    private var nodes: [String: SemanticNode] = [:]
    private var edges: [String: SemanticEdge] = [:]
    private var qualifiedIndex: [String: [String]] = [:]
    private var nodeIdentityByID: [String: String] = [:]
    private var identityCollisions: Set<String> = []

    init(moduleName: String) {
        self.moduleName = moduleName
    }

    @discardableResult
    func addNode(
        kind: NodeKind,
        name: String,
        qualifiedName: String,
        discriminator: String = "declaration",
        identityFile: String? = nil,
        evidence: Evidence,
        mergeEvidence: Bool = false
    ) -> String {
        let stableDiscriminator = identityFile.map { "file:\($0)|\(discriminator)" } ?? discriminator
        let id = StableID.node(
            module: moduleName,
            qualifiedName: qualifiedName,
            kind: kind,
            discriminator: stableDiscriminator
        )
        let identity = [kind.rawValue, name, qualifiedName, stableDiscriminator].joined(separator: "|")
        if let existing = nodes[id] {
            let extensionPlaceholder = existing.evidence.allSatisfy { $0.kind == "extension-declaration" }
            let canonicalDeclaration = evidence.kind == "type-declaration" || evidence.kind == "swiftui-view"
            if nodeIdentityByID[id] != identity || (!mergeEvidence && !(extensionPlaceholder && canonicalDeclaration)) {
                identityCollisions.insert(identity)
            } else {
                nodes[id] = SemanticNode(
                    id: id,
                    kind: existing.kind,
                    name: existing.name,
                    qualifiedName: existing.qualifiedName,
                    evidence: canonicalEvidence(existing.evidence + [evidence]),
                    confidence: existing.confidence,
                    roles: existing.roles,
                    feature: existing.feature
                )
            }
        } else {
            nodes[id] = SemanticNode(id: id, kind: kind, name: name, qualifiedName: qualifiedName, evidence: [evidence])
            nodeIdentityByID[id] = identity
            qualifiedIndex[qualifiedName, default: []].append(id)
            qualifiedIndex[qualifiedName]?.sort()
        }
        return id
    }

    func addEdge(
        kind: EdgeKind,
        from: String,
        to: String,
        evidence: Evidence,
        confidence: Confidence = .deterministic
    ) {
        guard nodes[from] != nil, nodes[to] != nil else { return }
        let discriminator = evidence.kind
        let id = StableID.edge(kind: kind, from: from, to: to, discriminator: discriminator)
        if let existing = edges[id] {
            edges[id] = SemanticEdge(
                id: id,
                kind: existing.kind,
                from: existing.from,
                to: existing.to,
                evidence: canonicalEvidence(existing.evidence + [evidence]),
                confidence: existing.confidence
            )
        } else {
            edges[id] = SemanticEdge(id: id, kind: kind, from: from, to: to, evidence: [evidence], confidence: confidence)
        }
    }

    func nodeID(qualifiedName: String, file: String? = nil) -> String? {
        unique(preferred(qualifiedIndex[qualifiedName], file: file))
    }

    func node(id: String) -> SemanticNode? {
        nodes[id]
    }

    func mergeEvidence(into id: String, evidence: Evidence) {
        guard let existing = nodes[id] else { return }
        nodes[id] = SemanticNode(
            id: existing.id,
            kind: existing.kind,
            name: existing.name,
            qualifiedName: existing.qualifiedName,
            evidence: canonicalEvidence(existing.evidence + [evidence]),
            confidence: existing.confidence,
            roles: existing.roles,
            feature: existing.feature
        )
    }

    func resolve(name rawName: String, scopes: [String], file: String? = nil) -> String? {
        let name = normalizedReference(rawName)
        guard !name.isEmpty else { return nil }
        for scope in scopes.reversed() {
            if let matches = qualifiedIndex["\(scope).\(name)"],
               let resolved = unique(preferred(matches, file: file)) {
                return resolved
            }
        }
        return unique(preferred(qualifiedIndex[name], file: file))
    }

    func ownedNodes(of ownerID: String, kind: NodeKind) -> [SemanticNode] {
        let childIDs = Set(edges.values.filter { $0.kind == .owns && $0.from == ownerID }.map(\.to))
        return childIDs.compactMap { nodes[$0] }.filter { $0.kind == kind }.sorted {
            ($0.qualifiedName, $0.id) < ($1.qualifiedName, $1.id)
        }
    }

    func graph() throws -> SemanticGraph {
        guard identityCollisions.isEmpty else {
            throw GraphScannerError.stableIdentityCollision(Array(identityCollisions))
        }
        return SemanticGraph(nodes: Array(nodes.values), edges: Array(edges.values))
    }

    private func unique(_ ids: [String]?) -> String? {
        guard let ids, ids.count == 1 else { return nil }
        return ids[0]
    }

    private func preferred(_ ids: [String]?, file: String?) -> [String]? {
        guard let ids, let file, ids.count > 1 else { return ids }
        let local = ids.filter { nodes[$0]?.evidence.contains { $0.file == file } == true }
        return local.isEmpty ? ids : local
    }

    private func canonicalEvidence(_ values: [Evidence]) -> [Evidence] {
        Array(Set(values)).sorted {
            ($0.file, $0.startLine, $0.endLine, $0.kind) < ($1.file, $1.startLine, $1.endLine, $1.kind)
        }
    }

    private func normalizedReference(_ reference: String) -> String {
        reference
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "self.", with: "")
            .replacingOccurrences(of: "$", with: "")
    }
}

private class BaseVisitor: SyntaxVisitor {
    let builder: GraphBuilder
    let file: String
    let converter: SourceLocationConverter
    var ownerIDs: [String]
    var ownerNames: [String]

    init(builder: GraphBuilder, file: String, converter: SourceLocationConverter) {
        self.builder = builder
        self.file = file
        self.converter = converter
        let moduleID = StableID.node(module: builder.moduleName, qualifiedName: builder.moduleName, kind: .module)
        self.ownerIDs = [moduleID]
        self.ownerNames = [builder.moduleName]
        super.init(viewMode: .sourceAccurate)
    }

    var currentOwnerID: String { ownerIDs.last! }
    var currentOwnerName: String { ownerNames.last! }

    func qualified(_ name: String) -> String { "\(currentOwnerName).\(name)" }

    func scopedQualified(_ name: String, node: some SyntaxProtocol) -> String {
        let scopes = structuralScopes(for: node)
        return ([currentOwnerName] + scopes + [name]).joined(separator: ".")
    }

    func scopedResolutionCandidates(_ name: String, node: some SyntaxProtocol) -> [String] {
        let scopes = structuralScopes(for: node)
        var candidates: [String] = []
        for owner in ownerNames.reversed() {
            for count in stride(from: scopes.count, through: 0, by: -1) {
                candidates.append(([owner] + scopes.prefix(count) + [name]).joined(separator: "."))
            }
        }
        return candidates
    }

    func evidence(_ node: some SyntaxProtocol, kind: String) -> Evidence {
        let start = node.startLocation(converter: converter).line
        let end = node.endLocation(converter: converter).line
        return Evidence(file: file, startLine: start, endLine: max(start, end), kind: kind)
    }

    func wrapperName(_ node: VariableDeclSyntax) -> String? {
        for attribute in node.attributes {
            guard let syntax = attribute.as(AttributeSyntax.self) else { continue }
            let name = syntax.attributeName.trimmedDescription.split(separator: "(").first.map(String.init)
            if let name { return name.split(separator: ".").last.map(String.init) }
        }
        return nil
    }

    func isCallback(_ binding: PatternBindingSyntax) -> Bool {
        binding.typeAnnotation?.type.trimmedDescription.contains("->") == true
    }

    func functionDiscriminator(_ node: FunctionDeclSyntax) -> String {
        let parameters = node.signature.parameterClause.parameters.map { parameter in
            [
                parameter.firstName.text,
                parameter.secondName?.text ?? "",
                canonicalSyntax(parameter.type.trimmedDescription),
                parameter.ellipsis == nil ? "" : "...",
            ].joined(separator: ":")
        }.joined(separator: ",")
        let effects = canonicalSyntax(node.signature.effectSpecifiers?.trimmedDescription ?? "")
        let result = canonicalSyntax(node.signature.returnClause?.type.trimmedDescription ?? "Void")
        let generics = canonicalSyntax(node.genericParameterClause?.trimmedDescription ?? "")
        let requirements = canonicalSyntax(node.genericWhereClause?.trimmedDescription ?? "")
        let modifiers = canonicalSyntax(node.modifiers.trimmedDescription)
        return "function(\(parameters))->\(result)|\(effects)|\(generics)|\(requirements)|\(modifiers)"
    }

    func functionScopeName(_ node: FunctionDeclSyntax, qualifiedName: String) -> String {
        "\(qualifiedName)[\(functionDiscriminator(node))]"
    }

    func canonicalSyntax(_ value: String) -> String {
        value.filter { !$0.isWhitespace }
    }

    func fileScopedIdentity(_ modifiers: DeclModifierListSyntax) -> String? {
        modifiers.contains { modifier in
            modifier.name.text == "private" || modifier.name.text == "fileprivate"
        } ? file : nil
    }

    func stableNodeID(
        qualifiedName: String,
        kind: NodeKind,
        discriminator: String,
        identityFile: String?
    ) -> String {
        let stableDiscriminator = identityFile.map { "file:\($0)|\(discriminator)" } ?? discriminator
        return StableID.node(
            module: builder.moduleName,
            qualifiedName: qualifiedName,
            kind: kind,
            discriminator: stableDiscriminator
        )
    }

    private func structuralScopes(for node: some SyntaxProtocol) -> [String] {
        var scopes: [String] = []
        var ancestor = node.parent
        while let syntax = ancestor {
            if let clause = syntax.as(IfConfigClauseSyntax.self) {
                let keyword = clause.poundKeyword.text.replacingOccurrences(of: "#", with: "")
                let condition = canonicalSyntax(clause.condition?.trimmedDescription ?? "else")
                scopes.append("[ifconfig:\(keyword):\(condition):\(structuralPath(of: syntax))]")
            } else if syntax.is(ClosureExprSyntax.self) {
                scopes.append("[closure:\(structuralPath(of: syntax))]")
            } else if let block = syntax.as(CodeBlockSyntax.self),
                      block.parent?.is(FunctionDeclSyntax.self) != true {
                scopes.append("[block:\(structuralPath(of: syntax))]")
            }
            ancestor = syntax.parent
        }
        return scopes.reversed()
    }

    private func structuralPath(of node: Syntax) -> String {
        var components: [String] = []
        var current = node
        while let parent = current.parent {
            let children = parent.children(viewMode: .sourceAccurate)
            if let index = children.index(of: current) {
                components.append(String(children.distance(from: children.startIndex, to: index)))
            }
            if parent.is(SourceFileSyntax.self) || parent.is(FunctionDeclSyntax.self) ||
                parent.is(StructDeclSyntax.self) || parent.is(ClassDeclSyntax.self) ||
                parent.is(EnumDeclSyntax.self) || parent.is(ActorDeclSyntax.self) ||
                parent.is(ExtensionDeclSyntax.self) {
                break
            }
            current = parent
        }
        return components.reversed().joined(separator: "-")
    }
}

private final class DeclarationVisitor: BaseVisitor {
    private let predeclareOnly: Bool

    init(
        builder: GraphBuilder,
        file: String,
        converter: SourceLocationConverter,
        predeclareOnly: Bool = false
    ) {
        self.predeclareOnly = predeclareOnly
        super.init(builder: builder, file: file, converter: converter)
    }

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        enterType(name: node.name.text, isView: node.inheritanceClause?.inheritedTypes.contains(where: {
            $0.type.trimmedDescription.split(separator: ".").last == "View"
        }) == true, node: node)
        return .visitChildren
    }

    override func visitPost(_ node: StructDeclSyntax) { leaveOwner() }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        enterType(name: node.name.text, isView: false, node: node)
        return .visitChildren
    }

    override func visitPost(_ node: ClassDeclSyntax) { leaveOwner() }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        enterType(name: node.name.text, isView: false, node: node)
        return .visitChildren
    }

    override func visitPost(_ node: EnumDeclSyntax) { leaveOwner() }

    override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
        enterType(name: node.name.text, isView: false, node: node)
        return .visitChildren
    }

    override func visitPost(_ node: ActorDeclSyntax) { leaveOwner() }

    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        if predeclareOnly { return .skipChildren }
        enterExtension(node)
        return .visitChildren
    }

    override func visitPost(_ node: ExtensionDeclSyntax) {
        if !predeclareOnly { leaveOwner() }
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        if predeclareOnly { return .skipChildren }
        let name = node.name.text
        let qualifiedName = scopedQualified(name, node: node)
        let id = builder.addNode(
            kind: .function,
            name: name,
            qualifiedName: qualifiedName,
            discriminator: functionDiscriminator(node),
            identityFile: file,
            evidence: evidence(node, kind: "function-declaration")
        )
        builder.addEdge(kind: .owns, from: currentOwnerID, to: id, evidence: evidence(node, kind: "declaration-ownership"))
        ownerIDs.append(id)
        ownerNames.append(functionScopeName(node, qualifiedName: qualifiedName))
        return .visitChildren
    }

    override func visitPost(_ node: FunctionDeclSyntax) {
        if !predeclareOnly { leaveOwner() }
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        if predeclareOnly { return .skipChildren }
        let wrapper = wrapperName(node)
        for binding in node.bindings {
            guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else { continue }
            let kind = SwiftUIVocabulary.nodeKind(forPropertyWrapper: wrapper, isCallback: isCallback(binding))
            let qualifiedName = scopedQualified(identifier, node: binding)
            let propertyID = builder.addNode(
                kind: kind,
                name: identifier,
                qualifiedName: qualifiedName,
                identityFile: file,
                evidence: evidence(binding, kind: wrapper == nil ? "property-declaration" : "property-wrapper")
            )
            if let wrapper {
                builder.mergeEvidence(
                    into: propertyID,
                    evidence: evidence(binding, kind: "property-wrapper:\(wrapper)")
                )
            }
            builder.addEdge(
                kind: SwiftUIVocabulary.ownershipEdge(forPropertyWrapper: wrapper),
                from: currentOwnerID,
                to: propertyID,
                evidence: evidence(node, kind: wrapper == nil ? "declaration-ownership" : "property-wrapper")
            )
        }
        return .visitChildren
    }

    private func enterType(name: String, isView: Bool, node: some DeclGroupSyntax) {
        let kind: NodeKind = isView ? .view : .type
        let qualifiedName = scopedQualified(name, node: node)
        let id = builder.addNode(
            kind: kind,
            name: name,
            qualifiedName: qualifiedName,
            identityFile: fileScopedIdentity(node.modifiers),
            evidence: evidence(node, kind: isView ? "swiftui-view" : "type-declaration"),
            mergeEvidence: !predeclareOnly
        )
        builder.addEdge(kind: .owns, from: currentOwnerID, to: id, evidence: evidence(node, kind: "declaration-ownership"))
        ownerIDs.append(id)
        ownerNames.append(qualifiedName)
    }

    private func enterExtension(_ node: ExtensionDeclSyntax) {
        let extendedName = node.extendedType.trimmedDescription
        let resolved = scopedResolutionCandidates(extendedName, node: node).lazy
            .compactMap { self.builder.nodeID(qualifiedName: $0, file: self.file) }.first ??
            builder.resolve(name: extendedName, scopes: ownerNames, file: file)
        if let resolved, let type = builder.node(id: resolved) {
            builder.mergeEvidence(into: resolved, evidence: evidence(node, kind: "extension-declaration"))
            ownerIDs.append(resolved)
            ownerNames.append(type.qualifiedName)
            return
        }
        let name = extendedName.split(separator: ".").last.map(String.init) ?? extendedName
        let qualifiedName = scopedQualified(extendedName, node: node)
        let id = builder.addNode(
            kind: .type,
            name: name,
            qualifiedName: qualifiedName,
            evidence: evidence(node, kind: "extension-declaration"),
            mergeEvidence: true
        )
        builder.addEdge(kind: .owns, from: currentOwnerID, to: id, evidence: evidence(node, kind: "declaration-ownership"))
        ownerIDs.append(id)
        ownerNames.append(qualifiedName)
    }

    private func leaveOwner() {
        ownerIDs.removeLast()
        ownerNames.removeLast()
    }
}

private final class RelationshipVisitor: BaseVisitor {
    private struct SyntaxRangeKey: Hashable {
        let start: Int
        let end: Int
    }

    private struct OnChangeParameterBinding {
        let observedID: String
        let name: String
        let position: Int
        let evidence: Evidence
        let createsIdentityAlias: Bool
    }

    private struct ClosureReferenceFrame {
        let aliases: [String: String]
        let boundNames: Set<String>
    }

    private final class AssignmentParameterUseVisitor: SyntaxVisitor {
        private final class DirectReferenceVisitor: SyntaxVisitor {
            let parameterName: String
            var found = false

            init(parameterName: String) {
                self.parameterName = parameterName
                super.init(viewMode: .sourceAccurate)
            }

            override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
                RelationshipVisitor.closureParameterNames(in: node).contains(parameterName)
                    ? .skipChildren
                    : .visitChildren
            }

            override func visit(_ node: DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
                if node.baseName.text == parameterName {
                    found = true
                }
                return .skipChildren
            }
        }

        let parameterName: String
        var hasAssignmentUse = false
        var hasIdentityAssignment = false

        init(parameterName: String) {
            self.parameterName = parameterName
            super.init(viewMode: .sourceAccurate)
        }

        override func visit(_ node: SequenceExprSyntax) -> SyntaxVisitorContinueKind {
            let elements = Array(node.elements)
            guard let assignmentIndex = elements.firstIndex(where: { $0.is(AssignmentExprSyntax.self) }),
                  assignmentIndex + 1 < elements.count
            else { return .visitChildren }
            let rhsElements = elements[(assignmentIndex + 1)...]
            let referenceVisitor = DirectReferenceVisitor(parameterName: parameterName)
            for element in rhsElements {
                referenceVisitor.walk(element)
            }
            guard referenceVisitor.found else { return .skipChildren }

            hasAssignmentUse = true
            let rhsText = rhsElements.map(\.trimmedDescription).joined(separator: " ")
            let canonicalRHS = rhsText.filter { !$0.isWhitespace }
            let canonicalName = parameterName.filter { !$0.isWhitespace }
            if canonicalRHS == canonicalName || canonicalRHS == "(\(canonicalName))" {
                hasIdentityAssignment = true
            }
            return .skipChildren
        }

        override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
            RelationshipVisitor.closureParameterNames(in: node).contains(parameterName)
                ? .skipChildren
                : .visitChildren
        }
    }

    private var generatedCounters: [String: Int] = [:]
    private var generatedCallOwners: [SyntaxRangeKey: (id: String, qualifiedName: String)] = [:]
    private var pendingClosureTargets: [SyntaxRangeKey: (target: String, evidenceKind: String)] = [:]
    private var pendingBindingSetters: [SyntaxRangeKey: (binding: String, evidence: Evidence)] = [:]
    private var pendingOnChangeParameters: [SyntaxRangeKey: OnChangeParameterBinding] = [:]
    private var closureReferenceFrames: [ClosureReferenceFrame] = []
    private var assignmentTargetRanges: [(start: Int, end: Int)?] = []

    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        enterExistingType(name: node.name.text, isView: node.inheritanceClause?.inheritedTypes.contains(where: {
            $0.type.trimmedDescription.split(separator: ".").last == "View"
        }) == true, node: node)
        return .visitChildren
    }

    override func visitPost(_ node: StructDeclSyntax) { leaveOwner() }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        enterExistingType(name: node.name.text, isView: false, node: node)
        return .visitChildren
    }

    override func visitPost(_ node: ClassDeclSyntax) { leaveOwner() }

    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        enterExistingType(name: node.name.text, isView: false, node: node)
        return .visitChildren
    }

    override func visitPost(_ node: EnumDeclSyntax) { leaveOwner() }

    override func visit(_ node: ActorDeclSyntax) -> SyntaxVisitorContinueKind {
        enterExistingType(name: node.name.text, isView: false, node: node)
        return .visitChildren
    }

    override func visitPost(_ node: ActorDeclSyntax) { leaveOwner() }

    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        enterExistingExtension(node)
        return .visitChildren
    }

    override func visitPost(_ node: ExtensionDeclSyntax) { leaveOwner() }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        let name = node.name.text
        let qualifiedName = scopedQualified(name, node: node)
        let id = stableNodeID(
            qualifiedName: qualifiedName,
            kind: .function,
            discriminator: functionDiscriminator(node),
            identityFile: file
        )
        ownerIDs.append(id)
        ownerNames.append(functionScopeName(node, qualifiedName: qualifiedName))
        return .visitChildren
    }

    override func visitPost(_ node: FunctionDeclSyntax) { leaveOwner() }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        for binding in node.bindings {
            guard let identifier = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
                  let type = binding.typeAnnotation?.type,
                  let typeName = declaredTypeName(type.trimmedDescription),
                  let propertyID = builder.nodeID(
                    qualifiedName: scopedQualified(identifier, node: binding),
                    file: file
                  )
            else { continue }
            let typeID = resolveReference(typeName, node: type) ?? boundedSystemType(typeName, node: type)
            guard let typeID else { continue }
            builder.addEdge(
                kind: .typedAs,
                from: propertyID,
                to: typeID,
                evidence: evidence(type, kind: "declared-type")
            )
        }
        return .visitChildren
    }

    override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
        let parent = generatedOwner(for: node) ?? (currentOwnerID, currentOwnerName)
        let ordinal = nextOrdinal(role: "closure", owner: parent.1)
        let name = "closure#\(ordinal)"
        let qualifiedName = "\(parent.1).\(name)"
        let id = builder.addNode(
            kind: .closure,
            name: name,
            qualifiedName: qualifiedName,
            discriminator: "closure:\(ordinal)",
            identityFile: file,
            evidence: evidence(node, kind: "closure-expression")
        )
        builder.addEdge(kind: .creates, from: parent.0, to: id, evidence: evidence(node, kind: "closure-expression"))
        if let setter = pendingBindingSetters[syntaxKey(node)] {
            builder.addEdge(kind: .sets, from: setter.binding, to: id, evidence: setter.evidence)
        }
        if let pending = pendingClosureTargets[syntaxKey(node)] {
            builder.addEdge(
                kind: .passes,
                from: id,
                to: pending.target,
                evidence: evidence(node, kind: pending.evidenceKind)
            )
        }
        var referenceAliases: [String: String] = [:]
        if let parameter = pendingOnChangeParameters[syntaxKey(node)] {
            referenceAliases[parameter.name] = parameter.observedID
            if parameter.createsIdentityAlias {
                let parameterID = builder.addNode(
                    kind: .input,
                    name: parameter.name,
                    qualifiedName: "\(qualifiedName).\(parameter.name)",
                    discriminator: "onchange-new-value:\(parameter.position)",
                    identityFile: file,
                    evidence: parameter.evidence
                )
                builder.addEdge(kind: .owns, from: id, to: parameterID, evidence: parameter.evidence)
                builder.addEdge(kind: .aliases, from: parameterID, to: parameter.observedID, evidence: parameter.evidence)
            }
        }
        if builder.node(id: parent.0)?.name.hasPrefix("GeometryReader#") == true {
            for (position, parameterName) in Self.closureParameterNames(in: node).sorted().enumerated() {
                let parameterEvidence = evidence(node, kind: "geometry-proxy")
                let parameterID = builder.addNode(
                    kind: .input,
                    name: parameterName,
                    qualifiedName: "\(qualifiedName).\(parameterName)",
                    discriminator: "geometry-proxy:\(position)",
                    identityFile: file,
                    evidence: parameterEvidence
                )
                builder.addEdge(kind: .owns, from: id, to: parameterID, evidence: parameterEvidence)
                builder.addEdge(kind: .flowsTo, from: parent.0, to: parameterID, evidence: parameterEvidence)
                referenceAliases[parameterName] = parameterID
            }
        }
        closureReferenceFrames.append(ClosureReferenceFrame(
            aliases: referenceAliases,
            boundNames: Self.closureParameterNames(in: node)
        ))
        ownerIDs.append(id)
        ownerNames.append(qualifiedName)
        return .visitChildren
    }

    override func visitPost(_ node: ClosureExprSyntax) {
        closureReferenceFrames.removeLast()
        leaveOwner()
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        let callName = calledName(node.calledExpression)
        let callEvidence = evidence(node, kind: "function-call")

        if callName == "Binding",
           argument(named: "get", in: node)?.as(ClosureExprSyntax.self) != nil,
           let setter = argument(named: "set", in: node)?.as(ClosureExprSyntax.self) {
            let bindingID = makeBindingConstruction(node)
            pendingBindingSetters[syntaxKey(setter)] = (
                binding: bindingID,
                evidence: evidence(setter, kind: "binding-setter")
            )
            return .visitChildren
        }

        if SwiftUIVocabulary.modifiers.contains(callName) {
            let kind: NodeKind = ["onChange", "onTapGesture", "accessibilityAction"].contains(callName)
                ? .event : .effect
            let id = makeGenerated(kind: kind, role: callName, node: node, evidenceKind: "swiftui-modifier")
            addArgumentFlows(from: node, to: id)
            if callName == "onChange", let source = argument(named: "of", in: node), let sourceID = resolveOrCreate(source, evidence: callEvidence) {
                builder.addEdge(kind: .triggers, from: sourceID, to: id, evidence: evidence(source, kind: "onchange-source"))
                if let closure = node.trailingClosure,
                   let parameter = onChangeNewValueParameter(in: closure),
                   let use = closureParameterAssignmentUse(parameter.name, closure: closure) {
                    pendingOnChangeParameters[syntaxKey(closure)] = OnChangeParameterBinding(
                        observedID: sourceID,
                        name: parameter.name,
                        position: parameter.position,
                        evidence: parameter.evidence,
                        createsIdentityAlias: use
                    )
                }
            }
            if callName == "task", let source = argument(named: "id", in: node), let sourceID = resolveOrCreate(source, evidence: callEvidence) {
                builder.addEdge(kind: .triggers, from: sourceID, to: id, evidence: evidence(source, kind: "task-id"))
            }
            return .visitChildren
        }

        if SwiftUIVocabulary.controls.contains(callName) {
            let controlID = makeGenerated(kind: .effect, role: callName, node: node, evidenceKind: "swiftui-control")
            for argument in node.arguments {
                let expression = argument.expression
                let text = expression.trimmedDescription
                if text.contains("$") {
                    addBindingProjection(text: text, controlID: controlID, node: expression)
                } else if let valueID = resolveOrCreate(expression, evidence: callEvidence) {
                    builder.addEdge(kind: .reads, from: controlID, to: valueID, evidence: evidence(expression, kind: "control-argument"))
                }
            }
            return .visitChildren
        }

        if SwiftUIVocabulary.actions.contains(callName) {
            _ = makeGenerated(kind: .event, role: callName, node: node, evidenceKind: "swiftui-action")
            return .visitChildren
        }

        if SwiftUIVocabulary.containers.contains(callName) {
            let id = makeGenerated(kind: .effect, role: callName, node: node, evidenceKind: "swiftui-container")
            addArgumentFlows(from: node, to: id)
            return .visitChildren
        }

        if SwiftUIVocabulary.platformCommands.contains(callName) {
            _ = makeGenerated(kind: .effect, role: callName, node: node, evidenceKind: "platform-command")
            return .visitChildren
        }

        if let calleeID = resolveReference(callName, node: node.calledExpression) ??
            resolveObservedCallTarget(node.calledExpression) {
            builder.addEdge(
                kind: .calls,
                from: currentOwnerID,
                to: calleeID,
                evidence: evidence(
                    node,
                    kind: isAssignmentTransformCall(node) ? "assignment-transform-call" : "function-call"
                )
            )
            for argument in node.arguments where argument.expression.as(ClosureExprSyntax.self) == nil {
                if let sourceID = resolveOrCreate(argument.expression, evidence: callEvidence) {
                    builder.addEdge(
                        kind: .flowsTo,
                        from: sourceID,
                        to: calleeID,
                        evidence: evidence(argument, kind: "argument-flow")
                    )
                }
            }
        }

        if callName.first?.isUppercase == true,
           let targetTypeID = resolveReference(callName, node: node.calledExpression),
            let targetType = builder.node(id: targetTypeID) {
            for argument in node.arguments {
                guard let label = argument.label?.text,
                      let propertyID = builder.resolve(name: "\(targetType.qualifiedName).\(label)", scopes: [])
                else { continue }
                if let closure = argument.expression.as(ClosureExprSyntax.self),
                   builder.node(id: propertyID)?.kind == .callback {
                    pendingClosureTargets[syntaxKey(closure)] = (propertyID, "labeled-closure-argument")
                } else if let sourceID = resolveOrCreate(argument.expression, evidence: callEvidence) {
                    builder.addEdge(kind: .passes, from: sourceID, to: propertyID, evidence: evidence(argument, kind: "initializer-argument"))
                }
            }
            if let trailingClosure = node.trailingClosure {
                let explicitLabels = Set(node.arguments.compactMap { $0.label?.text })
                let callbacks = builder.ownedNodes(of: targetTypeID, kind: .callback).filter {
                    !explicitLabels.contains($0.name)
                }
                if callbacks.count == 1 {
                    pendingClosureTargets[syntaxKey(trailingClosure)] = (callbacks[0].id, "trailing-closure-argument")
                }
            }
        }
        return .visitChildren
    }

    override func visit(_ node: MacroExpansionExprSyntax) -> SyntaxVisitorContinueKind {
        guard node.macroName.text == "Preview" else { return .visitChildren }
        makePreview(node)
        return .visitChildren
    }

    override func visit(_ node: MacroExpansionDeclSyntax) -> SyntaxVisitorContinueKind {
        guard node.macroName.text == "Preview" else { return .visitChildren }
        makePreview(node)
        return .visitChildren
    }

    private func makePreview(_ node: some SyntaxProtocol) {
        let ordinal = nextOrdinal(role: "Preview", owner: currentOwnerName)
        let name = "Preview#\(ordinal)"
        let qualifiedName = qualified(name)
        let id = builder.addNode(
            kind: .effect,
            name: name,
            qualifiedName: qualifiedName,
            discriminator: "preview:\(ordinal)",
            identityFile: file,
            evidence: evidence(node, kind: "preview-composition")
        )
        builder.addEdge(
            kind: .creates,
            from: currentOwnerID,
            to: id,
            evidence: evidence(node, kind: "preview-composition")
        )
        generatedCallOwners[syntaxKey(node)] = (id, qualifiedName)
    }

    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        guard !isInsideAssignmentTarget(node) else { return .visitChildren }
        let text = node.trimmedDescription
        if let target = resolveOrCreate(text: text, node: node, evidenceKind: "member-access") {
            builder.addEdge(kind: .reads, from: currentOwnerID, to: target, evidence: evidence(node, kind: "member-access"))
        }
        return .visitChildren
    }

    override func visit(_ node: DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
        guard !isInsideAssignmentTarget(node) else { return .visitChildren }
        let text = node.baseName.text
        guard !text.hasPrefix("$"), let target = resolveReference(text, node: node), target != currentOwnerID else {
            return .visitChildren
        }
        builder.addEdge(kind: .reads, from: currentOwnerID, to: target, evidence: evidence(node, kind: "property-access"))
        return .visitChildren
    }

    override func visit(_ node: SequenceExprSyntax) -> SyntaxVisitorContinueKind {
        let elements = Array(node.elements)
        guard let assignmentIndex = elements.firstIndex(where: { $0.is(AssignmentExprSyntax.self) }),
              assignmentIndex > 0,
              assignmentIndex + 1 < elements.count
        else {
            assignmentTargetRanges.append(nil)
            return .visitChildren
        }
        let lhs = elements[assignmentIndex - 1]
        let rhsElements = elements[(assignmentIndex + 1)...]
        assignmentTargetRanges.append((
            start: lhs.positionAfterSkippingLeadingTrivia.utf8Offset,
            end: lhs.endPositionBeforeTrailingTrivia.utf8Offset
        ))
        guard let targetID = resolveOrCreate(text: lhs.trimmedDescription, node: lhs, evidenceKind: "assignment-target") else {
            return .visitChildren
        }
        let assignmentEvidence = evidence(node, kind: "assignment")
        builder.addEdge(kind: .writes, from: currentOwnerID, to: targetID, evidence: assignmentEvidence)
        let rhsText = rhsElements.map(\.trimmedDescription).joined(separator: " ")
        let references = references(in: rhsText)
        if references.count == 1,
           isIdentityExpression(rhsText, reference: references[0]),
           let sourceID = resolveOrCreate(text: references[0], node: node, evidenceKind: "assignment-source") {
            builder.addEdge(
                kind: .copiesTo,
                from: sourceID,
                to: targetID,
                evidence: assignmentEvidence
            )
        } else {
            for sourceID in Set(references.compactMap { resolveDependency($0, node: node) }).sorted() {
                builder.addEdge(
                    kind: .derivesFrom,
                    from: targetID,
                    to: sourceID,
                    evidence: evidence(node, kind: "assignment-transform")
                )
            }
        }
        return .visitChildren
    }

    override func visitPost(_ node: SequenceExprSyntax) {
        assignmentTargetRanges.removeLast()
    }

    private func enterExistingType(name: String, isView: Bool, node: some DeclGroupSyntax) {
        let qualifiedName = scopedQualified(name, node: node)
        let kind: NodeKind = isView ? .view : .type
        let id = stableNodeID(
            qualifiedName: qualifiedName,
            kind: kind,
            discriminator: "declaration",
            identityFile: fileScopedIdentity(node.modifiers)
        )
        ownerIDs.append(id)
        ownerNames.append(qualifiedName)
    }

    private func enterExistingExtension(_ node: ExtensionDeclSyntax) {
        let extendedName = node.extendedType.trimmedDescription
        let resolved = scopedResolutionCandidates(extendedName, node: node).lazy
            .compactMap { self.builder.nodeID(qualifiedName: $0, file: self.file) }.first ??
            builder.resolve(name: extendedName, scopes: ownerNames, file: file)
        let name = extendedName.split(separator: ".").last.map(String.init) ?? extendedName
        let qualifiedName = scopedQualified(extendedName, node: node)
        let id = resolved ?? StableID.node(module: builder.moduleName, qualifiedName: qualifiedName, kind: .type)
        ownerIDs.append(id)
        ownerNames.append(builder.node(id: id)?.qualifiedName ?? "\(currentOwnerName).\(name)")
    }

    private func makeGenerated(kind: NodeKind, role: String, node: FunctionCallExprSyntax, evidenceKind: String) -> String {
        let ordinal = nextOrdinal(role: role, owner: currentOwnerName)
        let name = "\(role)#\(ordinal)"
        let qualifiedName = qualified(name)
        let id = builder.addNode(
            kind: kind,
            name: name,
            qualifiedName: qualifiedName,
            discriminator: "\(role):\(ordinal)",
            identityFile: file,
            evidence: evidence(node, kind: evidenceKind)
        )
        builder.addEdge(kind: .creates, from: currentOwnerID, to: id, evidence: evidence(node, kind: evidenceKind))
        generatedCallOwners[syntaxKey(node)] = (id, qualifiedName)
        return id
    }

    private func makeBindingConstruction(_ node: FunctionCallExprSyntax) -> String {
        let parent = enclosingGeneratedOwner(for: node) ?? (currentOwnerID, currentOwnerName)
        let ordinal = nextOrdinal(role: "Binding", owner: parent.1)
        let name = "Binding#\(ordinal)"
        let qualifiedName = "\(parent.1).\(name)"
        let bindingID = builder.addNode(
            kind: .binding,
            name: name,
            qualifiedName: qualifiedName,
            discriminator: "binding-construction:\(ordinal)",
            identityFile: file,
            evidence: evidence(node, kind: "binding-construction")
        )
        if isBindingFactoryContext(node) {
            _ = builder.addNode(
                kind: .binding,
                name: name,
                qualifiedName: qualifiedName,
                discriminator: "binding-construction:\(ordinal)",
                identityFile: file,
                evidence: evidence(node, kind: "binding-factory"),
                mergeEvidence: true
            )
        }
        builder.addEdge(
            kind: .creates,
            from: parent.0,
            to: bindingID,
            evidence: evidence(node, kind: "binding-construction")
        )
        if builder.node(id: parent.0)?.evidence.contains(where: { $0.kind == "swiftui-control" }) == true {
            builder.addEdge(
                kind: .binds,
                from: parent.0,
                to: bindingID,
                evidence: evidence(node, kind: "control-binding")
            )
        }
        generatedCallOwners[syntaxKey(node)] = (bindingID, qualifiedName)
        return bindingID
    }

    private func addBindingProjection(text: String, controlID: String, node: some SyntaxProtocol) {
        guard let projected = firstReference(in: text), projected.contains("$") else { return }
        let baseReference = projected.replacingOccurrences(of: "$", with: "")
        let projectionName = projected.split(separator: ".").last.map(String.init) ?? projected
        let controlName = builder.node(id: controlID)?.qualifiedName ?? currentOwnerName
        let qualifiedName = "\(controlName).\(projectionName)"
        let projectionID = builder.addNode(
            kind: .binding,
            name: projectionName,
            qualifiedName: qualifiedName,
            discriminator: "projection:\(baseReference)",
            identityFile: file,
            evidence: evidence(node, kind: "binding-projection")
        )
        builder.addEdge(kind: .creates, from: controlID, to: projectionID, evidence: evidence(node, kind: "binding-projection"))
        if let baseID = resolveOrCreate(text: baseReference, node: node, evidenceKind: "binding-projection") {
            builder.addEdge(kind: .aliases, from: projectionID, to: baseID, evidence: evidence(node, kind: "binding-projection"))
        }
        builder.addEdge(kind: .binds, from: controlID, to: projectionID, evidence: evidence(node, kind: "control-binding"))
    }

    private func resolveOrCreate(_ expression: ExprSyntax, evidence: Evidence) -> String? {
        resolveOrCreate(text: expression.trimmedDescription, node: expression, evidenceKind: evidence.kind)
    }

    private func resolveObservedCallTarget(_ expression: ExprSyntax) -> String? {
        let text = expression.trimmedDescription
        guard let reference = firstReference(in: text), reference.contains("."),
              let rootName = reference.replacingOccurrences(of: "self.", with: "")
                .split(separator: ".").first.map(String.init),
              let rootID = resolveReference(rootName, node: expression),
              let root = builder.node(id: rootID),
              [.input, .observableState, .property, .binding, .state].contains(root.kind)
        else { return nil }
        return resolveOrCreate(
            text: text,
            node: expression,
            evidenceKind: "function-call-target"
        )
    }

    private func resolveOrCreate(
        text: String,
        node: some SyntaxProtocol,
        evidenceKind: String
    ) -> String? {
        guard let reference = firstReference(in: text) else { return nil }
        if let resolved = resolveReference(reference, node: node) { return resolved }
        guard reference.contains(".") else { return nil }
        let name = reference.split(separator: ".").last.map(String.init) ?? reference
        let memberID = builder.addNode(
            kind: .property,
            name: name,
            qualifiedName: "\(nearestDeclarationScope).\(reference.replacingOccurrences(of: "self.", with: ""))",
            discriminator: "syntax-reference",
            identityFile: file,
            evidence: evidence(node, kind: evidenceKind),
            mergeEvidence: true
        )
        let rootName = reference
            .replacingOccurrences(of: "self.", with: "")
            .split(separator: ".")
            .first
            .map(String.init)
        if let rootName,
           let rootID = resolveReference(rootName, node: node),
           let root = builder.node(id: rootID),
           [.input, .observableState, .property, .binding, .state].contains(root.kind) {
            builder.addEdge(
                kind: .observes,
                from: rootID,
                to: memberID,
                evidence: evidence(
                    node,
                    kind: root.kind == .input || root.kind == .observableState
                        ? "observable-member" : "member-reference"
                )
            )
        }
        return memberID
    }

    private func argument(named name: String, in call: FunctionCallExprSyntax) -> ExprSyntax? {
        call.arguments.first(where: { $0.label?.text == name })?.expression
    }

    private func addArgumentFlows(from call: FunctionCallExprSyntax, to targetID: String) {
        for argument in call.arguments where argument.expression.as(ClosureExprSyntax.self) == nil {
            guard let sourceID = resolveOrCreate(
                argument.expression,
                evidence: evidence(argument, kind: "argument-flow")
            ) else { continue }
            builder.addEdge(
                kind: .flowsTo,
                from: sourceID,
                to: targetID,
                evidence: evidence(argument, kind: "argument-flow")
            )
        }
    }

    private func declaredTypeName(_ text: String) -> String? {
        let withoutOptional = text
            .replacingOccurrences(of: "?", with: "")
            .replacingOccurrences(of: "!", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let head = withoutOptional.split(separator: "<", maxSplits: 1).first.map(String.init) ?? withoutOptional
        let candidate = head.split(whereSeparator: { $0.isWhitespace }).last.map(String.init) ?? head
        guard !candidate.isEmpty, candidate != "some", candidate != "any" else { return nil }
        return candidate
    }

    private func boundedSystemType(_ name: String, node: some SyntaxProtocol) -> String? {
        let qualifiedName: String
        switch name {
        case "TextSelection": qualifiedName = "SwiftUI.TextSelection"
        default: return nil
        }
        return builder.addNode(
            kind: .type,
            name: name,
            qualifiedName: qualifiedName,
            discriminator: "bounded-system-type",
            evidence: evidence(node, kind: "bounded-system-type"),
            mergeEvidence: true
        )
    }

    private func onChangeNewValueParameter(
        in closure: ClosureExprSyntax
    ) -> (name: String, position: Int, evidence: Evidence)? {
        guard let clause = closure.signature?.parameterClause else { return nil }
        let parameters: [(name: String, evidence: Evidence)]
        switch clause {
        case .simpleInput(let list):
            parameters = list.map { parameter in
                (parameter.name.text, evidence(parameter, kind: "onchange-new-value"))
            }
        case .parameterClause(let clause):
            parameters = clause.parameters.map { parameter in
                (
                    parameter.secondName?.text ?? parameter.firstName.text,
                    evidence(parameter, kind: "onchange-new-value")
                )
            }
        }
        guard parameters.count == 1 || parameters.count == 2 else { return nil }
        let position = parameters.count - 1
        let parameter = parameters[position]
        guard parameter.name != "_" else { return nil }
        return (parameter.name, position, parameter.evidence)
    }

    private static func closureParameterNames(in closure: ClosureExprSyntax) -> Set<String> {
        guard let clause = closure.signature?.parameterClause else { return [] }
        let names: [String]
        switch clause {
        case .simpleInput(let list):
            names = list.map { $0.name.text }
        case .parameterClause(let clause):
            names = clause.parameters.map { $0.secondName?.text ?? $0.firstName.text }
        }
        return Set(names.filter { $0 != "_" })
    }

    private func closureParameterAssignmentUse(
        _ name: String,
        closure: ClosureExprSyntax
    ) -> Bool? {
        let visitor = AssignmentParameterUseVisitor(parameterName: name)
        visitor.walk(closure.statements)
        guard visitor.hasAssignmentUse else { return nil }
        return visitor.hasIdentityAssignment
    }

    private var nearestDeclarationScope: String {
        for (id, name) in zip(ownerIDs, ownerNames).reversed() {
            guard let node = builder.node(id: id) else { continue }
            if node.kind == .view || node.kind == .type || node.kind == .module { return name }
        }
        return builder.moduleName
    }

    private func calledName(_ expression: ExprSyntax) -> String {
        if let member = expression.as(MemberAccessExprSyntax.self) { return member.declName.baseName.text }
        if let reference = expression.as(DeclReferenceExprSyntax.self) { return reference.baseName.text }
        return expression.trimmedDescription.split(separator: ".").last.map(String.init) ?? expression.trimmedDescription
    }

    private func generatedOwner(for closure: ClosureExprSyntax) -> (String, String)? {
        var ancestor = closure.parent
        while let syntax = ancestor {
            if let owner = generatedCallOwners[syntaxKey(syntax)] {
                return owner
            }
            ancestor = syntax.parent
        }
        return nil
    }

    private func enclosingGeneratedOwner(for call: FunctionCallExprSyntax) -> (String, String)? {
        var ancestor = call.parent
        while let syntax = ancestor {
            if let owner = generatedCallOwners[syntaxKey(syntax)] {
                return owner
            }
            ancestor = syntax.parent
        }
        return nil
    }

    private func isBindingFactoryContext(_ call: FunctionCallExprSyntax) -> Bool {
        guard !ownerIDs.contains(where: { builder.node(id: $0)?.kind == .view }) else { return false }
        var ancestor = call.parent
        while let syntax = ancestor {
            if let function = syntax.as(FunctionDeclSyntax.self) {
                return isBindingType(function.signature.returnClause?.type.trimmedDescription)
            }
            if let binding = syntax.as(PatternBindingSyntax.self),
               let type = binding.typeAnnotation?.type.trimmedDescription {
                return isBindingType(type)
            }
            if syntax.is(StructDeclSyntax.self) || syntax.is(ClassDeclSyntax.self) ||
                syntax.is(EnumDeclSyntax.self) || syntax.is(ActorDeclSyntax.self) {
                return false
            }
            ancestor = syntax.parent
        }
        return false
    }

    private func isBindingType(_ type: String?) -> Bool {
        guard let type else { return false }
        let canonical = type.filter { !$0.isWhitespace }
        return canonical == "Binding" || canonical.hasPrefix("Binding<") ||
            canonical.contains(".Binding<")
    }

    private func isAssignmentTransformCall(_ call: FunctionCallExprSyntax) -> Bool {
        var ancestor = call.parent
        while let syntax = ancestor {
            if let sequence = syntax.as(SequenceExprSyntax.self) {
                let elements = Array(sequence.elements)
                guard let assignment = elements.firstIndex(where: { $0.is(AssignmentExprSyntax.self) }),
                      assignment + 1 < elements.count
                else { return false }
                let rhsStart = elements[assignment + 1].positionAfterSkippingLeadingTrivia.utf8Offset
                return call.positionAfterSkippingLeadingTrivia.utf8Offset >= rhsStart
            }
            if syntax.is(CodeBlockItemSyntax.self) { return false }
            ancestor = syntax.parent
        }
        return false
    }

    private func syntaxKey(_ node: some SyntaxProtocol) -> SyntaxRangeKey {
        SyntaxRangeKey(
            start: node.positionAfterSkippingLeadingTrivia.utf8Offset,
            end: node.endPositionBeforeTrailingTrivia.utf8Offset
        )
    }

    private func nextOrdinal(role: String, owner: String) -> Int {
        let key = "\(owner)|\(role)"
        generatedCounters[key, default: 0] += 1
        return generatedCounters[key]!
    }

    private func isInsideAssignmentTarget(_ node: some SyntaxProtocol) -> Bool {
        let position = node.positionAfterSkippingLeadingTrivia.utf8Offset
        return assignmentTargetRanges.contains { range in
            guard let range else { return false }
            return position >= range.start && position < range.end
        }
    }

    private func firstReference(in text: String) -> String? {
        references(in: text).first
    }

    private func references(in text: String) -> [String] {
        let pattern = #"\$?[A-Za-z_][A-Za-z0-9_]*(?:\.\$?[A-Za-z_][A-Za-z0-9_]*)*"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let excluded: Set<String> = [
            "true", "false", "nil", "String", "Int", "Double", "Float", "Bool",
        ]
        var seen: Set<String> = []
        return regex.matches(in: text, range: NSRange(text.startIndex..., in: text)).compactMap { match in
            guard let range = Range(match.range, in: text) else { return nil }
            let candidate = String(text[range])
            guard !excluded.contains(candidate), seen.insert(candidate).inserted else { return nil }
            return candidate
        }
    }

    private func isIdentityExpression(_ expression: String, reference: String) -> Bool {
        let canonicalExpression = expression.filter { !$0.isWhitespace }
        let canonicalReference = reference.filter { !$0.isWhitespace }
        return canonicalExpression == canonicalReference || canonicalExpression == "(\(canonicalReference))"
    }

    private func resolveDependency(_ reference: String, node: some SyntaxProtocol) -> String? {
        if reference.contains("."),
           let root = reference
            .replacingOccurrences(of: "self.", with: "")
            .split(separator: ".")
            .first
            .map(String.init),
           let rootID = resolveReference(root, node: node) {
            return rootID
        }
        return resolveOrCreate(text: reference, node: node, evidenceKind: "assignment-source")
    }

    private func resolveReference(_ reference: String, node: some SyntaxProtocol) -> String? {
        for frame in closureReferenceFrames.reversed() {
            if let target = frame.aliases[reference] { return target }
            if frame.boundNames.contains(reference) { return nil }
        }
        for candidate in scopedResolutionCandidates(reference, node: node) {
            if let id = builder.nodeID(qualifiedName: candidate, file: file) { return id }
        }
        return builder.resolve(name: reference, scopes: ownerNames, file: file)
    }

    private func leaveOwner() {
        ownerIDs.removeLast()
        ownerNames.removeLast()
    }
}
