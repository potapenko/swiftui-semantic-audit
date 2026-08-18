import CryptoKit
import Foundation

public enum AnalysisRole: String, Codable, CaseIterable, Sendable {
    case applicationModel = "application-model"
    case featureModel = "feature-model"
    case controller
    case store
    case presenter
    case repository
    case service
    case player
    case dependencyBundle = "dependency-bundle"
    case effectSink = "effect-sink"
}

public enum AnalysisConfigurationError: Error, LocalizedError, Equatable {
    case missing(String)
    case malformed(String)
    case unsupportedSchema(Int)
    case unknownFields([String])
    case invalidQualifiedName(String)
    case invalidFeature(String)
    case unsafePath(String)

    public var errorDescription: String? {
        switch self {
        case .missing(let path): "analysis configuration does not exist: \(path)"
        case .malformed(let detail): "malformed analysis configuration: \(detail)"
        case .unsupportedSchema(let version): "unsupported analysis configuration schema \(version)"
        case .unknownFields(let fields): "unknown analysis configuration fields: \(fields.sorted().joined(separator: ", "))"
        case .invalidQualifiedName(let name): "invalid configured qualified name: \(name)"
        case .invalidFeature(let feature): "invalid configured feature: \(feature)"
        case .unsafePath(let path): "unsafe configured relative path prefix: \(path)"
        }
    }
}

public struct AnalysisConfiguration: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let compositionRoots: [String]
    public let typeRoles: [String: AnalysisRole]
    public let typeFeatures: [String: String]
    public let pathFeatures: [String: String]
    public let passiveEnvironmentValues: [String]

    public init(
        schemaVersion: Int = 1,
        compositionRoots: [String] = [],
        typeRoles: [String: AnalysisRole] = [:],
        typeFeatures: [String: String] = [:],
        pathFeatures: [String: String] = [:],
        passiveEnvironmentValues: [String] = []
    ) throws {
        guard schemaVersion == 1 else { throw AnalysisConfigurationError.unsupportedSchema(schemaVersion) }
        for name in compositionRoots + Array(typeRoles.keys) + Array(typeFeatures.keys) {
            guard Self.isQualifiedName(name) else { throw AnalysisConfigurationError.invalidQualifiedName(name) }
        }
        for feature in Array(typeFeatures.values) + Array(pathFeatures.values) {
            guard Self.isFeature(feature) else { throw AnalysisConfigurationError.invalidFeature(feature) }
        }
        for path in pathFeatures.keys { try Self.validatePath(path) }
        self.schemaVersion = schemaVersion
        self.compositionRoots = Array(Set(compositionRoots)).sorted()
        self.typeRoles = typeRoles
        self.typeFeatures = typeFeatures
        self.pathFeatures = pathFeatures
        self.passiveEnvironmentValues = Array(Set(passiveEnvironmentValues)).sorted()
    }

    public static func load(explicitURL: URL?, sourceURL: URL) throws -> AnalysisConfiguration? {
        let candidate: URL
        if let explicitURL {
            candidate = explicitURL.standardizedFileURL
            guard FileManager.default.fileExists(atPath: candidate.path) else {
                throw AnalysisConfigurationError.missing(candidate.path)
            }
        } else {
            var isDirectory: ObjCBool = false
            let root = sourceURL.standardizedFileURL
            _ = FileManager.default.fileExists(atPath: root.path, isDirectory: &isDirectory)
            candidate = (isDirectory.boolValue ? root : root.deletingLastPathComponent())
                .appendingPathComponent(".swiftui-audit.json")
            guard FileManager.default.fileExists(atPath: candidate.path) else { return nil }
        }
        do {
            let data = try Data(contentsOf: candidate)
            try DuplicateJSONKeyValidator.validate(data)
            let object = try JSONSerialization.jsonObject(with: data)
            guard let dictionary = object as? [String: Any] else {
                throw AnalysisConfigurationError.malformed("root must be an object")
            }
            let allowed: Set<String> = [
                "schemaVersion", "compositionRoots", "typeRoles", "typeFeatures",
                "pathFeatures", "passiveEnvironmentValues",
            ]
            let unknown = Set(dictionary.keys).subtracting(allowed)
            guard unknown.isEmpty else { throw AnalysisConfigurationError.unknownFields(Array(unknown)) }
            let decoded = try JSONDecoder().decode(RawConfiguration.self, from: data)
            return try AnalysisConfiguration(
                schemaVersion: decoded.schemaVersion,
                compositionRoots: decoded.compositionRoots ?? [],
                typeRoles: decoded.typeRoles ?? [:],
                typeFeatures: decoded.typeFeatures ?? [:],
                pathFeatures: decoded.pathFeatures ?? [:],
                passiveEnvironmentValues: decoded.passiveEnvironmentValues ?? []
            )
        } catch let error as AnalysisConfigurationError {
            throw error
        } catch {
            throw AnalysisConfigurationError.malformed(error.localizedDescription)
        }
    }

    public var digest: String {
        let canonical = CanonicalConfiguration(
            schemaVersion: schemaVersion,
            compositionRoots: compositionRoots.sorted(),
            typeRoles: typeRoles.map { KeyValue(key: $0.key, value: $0.value.rawValue) }.sorted(),
            typeFeatures: typeFeatures.map(KeyValue.init).sorted(),
            pathFeatures: pathFeatures.map(KeyValue.init).sorted(),
            passiveEnvironmentValues: passiveEnvironmentValues.sorted()
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        let data = (try? encoder.encode(canonical)) ?? Data()
        return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    public func applying(to graph: SemanticGraph) -> SemanticGraph {
        let nodes = graph.nodes.map { node -> SemanticNode in
            var roles = node.roles
            if let role = typeRoles[node.qualifiedName] { roles.append(role.rawValue) }
            if compositionRoots.contains(node.qualifiedName) { roles.append("composition-root") }
            let exactFeature = typeFeatures[node.qualifiedName]
            let pathFeature = node.evidence.lazy.compactMap { evidence in
                pathFeatures.sorted(by: { $0.key.count > $1.key.count }).first {
                    evidence.file.hasPrefix($0.key)
                }?.value
            }.first
            return SemanticNode(
                id: node.id,
                kind: node.kind,
                name: node.name,
                qualifiedName: node.qualifiedName,
                evidence: node.evidence,
                confidence: node.confidence,
                roles: roles,
                feature: exactFeature ?? node.feature ?? pathFeature
            )
        }
        return SemanticGraph(
            schemaVersion: graph.schemaVersion,
            resolution: graph.resolution,
            configurationDigest: digest,
            nodes: nodes,
            edges: graph.edges
        )
    }

    private static func isQualifiedName(_ value: String) -> Bool {
        !value.isEmpty && !value.contains("/") && !value.contains("..") &&
            value.split(separator: ".").allSatisfy { component in
                component.first.map { $0.isLetter || $0 == "_" } == true &&
                    component.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" }
            }
    }

    private static func isFeature(_ value: String) -> Bool {
        !value.isEmpty && value.allSatisfy { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
    }

    private static func validatePath(_ value: String) throws {
        guard !value.isEmpty, !value.hasPrefix("/"), !value.contains("\\"),
              !value.split(separator: "/", omittingEmptySubsequences: false).contains("..")
        else { throw AnalysisConfigurationError.unsafePath(value) }
    }
}

private struct RawConfiguration: Decodable {
    let schemaVersion: Int
    let compositionRoots: [String]?
    let typeRoles: [String: AnalysisRole]?
    let typeFeatures: [String: String]?
    let pathFeatures: [String: String]?
    let passiveEnvironmentValues: [String]?
}

private struct KeyValue: Codable, Comparable {
    let key: String
    let value: String
    static func < (lhs: KeyValue, rhs: KeyValue) -> Bool { (lhs.key, lhs.value) < (rhs.key, rhs.value) }
}

private struct CanonicalConfiguration: Encodable {
    let schemaVersion: Int
    let compositionRoots: [String]
    let typeRoles: [KeyValue]
    let typeFeatures: [KeyValue]
    let pathFeatures: [KeyValue]
    let passiveEnvironmentValues: [String]
}

private struct DuplicateJSONKeyValidator {
    private enum ValidationError: Error, LocalizedError {
        case duplicate(String)

        var errorDescription: String? {
            switch self {
            case .duplicate(let key): "duplicate JSON key: \(key)"
            }
        }
    }

    private let bytes: [UInt8]
    private var index = 0

    static func validate(_ data: Data) throws {
        var validator = DuplicateJSONKeyValidator(bytes: Array(data))
        try validator.scanValue()
        validator.skipWhitespace()
    }

    private mutating func scanValue() throws {
        skipWhitespace()
        guard index < bytes.count else { return }
        switch bytes[index] {
        case 0x7B: try scanObject()
        case 0x5B: try scanArray()
        case 0x22: _ = try scanString()
        default: scanPrimitive()
        }
    }

    private mutating func scanObject() throws {
        index += 1
        var keys: Set<String> = []
        while index < bytes.count {
            skipWhitespace()
            if consume(0x7D) { return }
            let key = try scanString()
            guard keys.insert(key).inserted else { throw ValidationError.duplicate(key) }
            skipWhitespace()
            _ = consume(0x3A)
            try scanValue()
            skipWhitespace()
            if consume(0x7D) { return }
            _ = consume(0x2C)
        }
    }

    private mutating func scanArray() throws {
        index += 1
        while index < bytes.count {
            skipWhitespace()
            if consume(0x5D) { return }
            try scanValue()
            skipWhitespace()
            if consume(0x5D) { return }
            _ = consume(0x2C)
        }
    }

    private mutating func scanString() throws -> String {
        let start = index
        guard consume(0x22) else { return "" }
        var escaped = false
        while index < bytes.count {
            let byte = bytes[index]
            index += 1
            if escaped {
                escaped = false
            } else if byte == 0x5C {
                escaped = true
            } else if byte == 0x22 {
                let data = Data(bytes[start..<index])
                return try JSONDecoder().decode(String.self, from: data)
            }
        }
        return ""
    }

    private mutating func scanPrimitive() {
        while index < bytes.count,
              ![UInt8(0x2C), 0x5D, 0x7D].contains(bytes[index]) {
            index += 1
        }
    }

    private mutating func skipWhitespace() {
        while index < bytes.count, [9, 10, 13, 32].contains(bytes[index]) { index += 1 }
    }

    private mutating func consume(_ byte: UInt8) -> Bool {
        guard index < bytes.count, bytes[index] == byte else { return false }
        index += 1
        return true
    }
}
