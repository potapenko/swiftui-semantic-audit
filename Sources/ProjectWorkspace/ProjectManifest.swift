import Foundation

public struct ProjectManifest: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1

    public let schemaVersion: Int
    public let sourceRoot: String
    public let analysisConfiguration: String?
    public let build: ProjectBuildConfiguration
    public let watch: ProjectWatchConfiguration
    public let baseline: String

    public init(
        sourceRoot: String,
        analysisConfiguration: String? = nil,
        build: ProjectBuildConfiguration,
        watch: ProjectWatchConfiguration = .init(),
        baseline: String = ".swiftui-audit/baseline"
    ) {
        self.schemaVersion = Self.currentSchemaVersion
        self.sourceRoot = sourceRoot
        self.analysisConfiguration = analysisConfiguration
        self.build = build
        self.watch = watch
        self.baseline = baseline
    }

    public static func load(projectRoot: URL) throws -> ProjectManifest {
        let url = projectRoot.appendingPathComponent(".swiftui-audit/project.json")
        let manifest: ProjectManifest
        do {
            manifest = try JSONDecoder().decode(ProjectManifest.self, from: Data(contentsOf: url))
        } catch {
            throw ProjectWorkspaceError.invalidManifest(error.localizedDescription)
        }
        guard manifest.schemaVersion == Self.currentSchemaVersion else {
            throw ProjectWorkspaceError.unsupportedSchema(manifest.schemaVersion)
        }
        try manifest.validate(projectRoot: projectRoot)
        return manifest
    }

    public func canonicalData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        var data = try encoder.encode(self)
        data.append(0x0A)
        return data
    }

    public func validate(projectRoot: URL) throws {
        try Self.validateRelative(sourceRoot, field: "sourceRoot", projectRoot: projectRoot)
        try Self.validateRelative(baseline, field: "baseline", projectRoot: projectRoot)
        if let analysisConfiguration {
            try Self.validateRelative(
                analysisConfiguration, field: "analysisConfiguration", projectRoot: projectRoot
            )
        }
        var sourceIsDirectory: ObjCBool = false
        let source = sourceURL(projectRoot: projectRoot).resolvingSymlinksInPath()
        guard FileManager.default.fileExists(atPath: source.path, isDirectory: &sourceIsDirectory),
              sourceIsDirectory.boolValue else {
            throw ProjectWorkspaceError.invalidManifest("sourceRoot does not exist: \(sourceRoot)")
        }
        if let configuration = configurationURL(projectRoot: projectRoot) {
            var configurationIsDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: configuration.path, isDirectory: &configurationIsDirectory),
                  !configurationIsDirectory.boolValue else {
                throw ProjectWorkspaceError.invalidManifest("analysisConfiguration is not a regular file")
            }
        }
        let baselineURL = baselineURL(projectRoot: projectRoot)
        let sourcePrefix = source.path.hasSuffix("/") ? source.path : source.path + "/"
        let baselinePrefix = baselineURL.path.hasSuffix("/") ? baselineURL.path : baselineURL.path + "/"
        guard source.path != baselineURL.path,
              !source.path.hasPrefix(baselinePrefix),
              !baselineURL.path.hasPrefix(sourcePrefix) else {
            throw ProjectWorkspaceError.invalidManifest("sourceRoot and baseline must not overlap")
        }
        guard watch.debounceMilliseconds > 0, watch.indexQuiescenceMilliseconds > 0 else {
            throw ProjectWorkspaceError.invalidManifest("watch delays must be positive")
        }
        try build.validate(projectRoot: projectRoot)
    }

    public func sourceURL(projectRoot: URL) -> URL {
        projectRoot.appendingPathComponent(sourceRoot, isDirectory: true).standardizedFileURL
    }

    public func configurationURL(projectRoot: URL) -> URL? {
        analysisConfiguration.map { projectRoot.appendingPathComponent($0) }
    }

    public func baselineURL(projectRoot: URL) -> URL {
        projectRoot.appendingPathComponent(baseline, isDirectory: true).standardizedFileURL
    }

    static func validateRelative(_ value: String, field: String, projectRoot: URL) throws {
        guard !value.isEmpty, !value.hasPrefix("/"), value != ".", value.split(separator: "/").allSatisfy({ $0 != ".." }) else {
            throw ProjectWorkspaceError.unsafePath(field, value)
        }
        let root = projectRoot.standardizedFileURL.resolvingSymlinksInPath()
        let resolved = root.appendingPathComponent(value).standardizedFileURL
        let prefix = root.path.hasSuffix("/") ? root.path : root.path + "/"
        guard resolved.path.hasPrefix(prefix) else { throw ProjectWorkspaceError.unsafePath(field, value) }
        let canonical = resolved.resolvingSymlinksInPath()
        guard canonical.path.hasPrefix(prefix) else { throw ProjectWorkspaceError.unsafePath(field, value) }
    }
}

public struct ProjectBuildConfiguration: Codable, Equatable, Sendable {
    public enum Kind: String, Codable, Sendable { case swiftPM = "swiftpm"; case xcode }

    public let kind: Kind
    public let container: String?
    public let scheme: String?
    public let platform: String?

    public init(kind: Kind, container: String? = nil, scheme: String? = nil, platform: String? = nil) {
        self.kind = kind
        self.container = container
        self.scheme = scheme
        self.platform = platform
    }

    func validate(projectRoot: URL) throws {
        switch kind {
        case .swiftPM:
            guard container == nil, scheme == nil, platform == nil else {
                throw ProjectWorkspaceError.invalidManifest("SwiftPM build cannot contain Xcode fields")
            }
        case .xcode:
            guard let container, let scheme, !scheme.isEmpty, let platform, !platform.isEmpty else {
                throw ProjectWorkspaceError.invalidManifest("Xcode build requires container, scheme, and platform")
            }
            try ProjectManifest.validateRelative(container, field: "build.container", projectRoot: projectRoot)
            guard container.hasSuffix(".xcodeproj") || container.hasSuffix(".xcworkspace") else {
                throw ProjectWorkspaceError.invalidManifest("Xcode container must be .xcodeproj or .xcworkspace")
            }
            guard FileManager.default.fileExists(atPath: projectRoot.appendingPathComponent(container).path) else {
                throw ProjectWorkspaceError.invalidManifest("Xcode container does not exist: \(container)")
            }
        }
    }
}

public struct ProjectWatchConfiguration: Codable, Equatable, Sendable {
    public let debounceMilliseconds: Int
    public let indexQuiescenceMilliseconds: Int

    public init(debounceMilliseconds: Int = 250, indexQuiescenceMilliseconds: Int = 1000) {
        self.debounceMilliseconds = debounceMilliseconds
        self.indexQuiescenceMilliseconds = indexQuiescenceMilliseconds
    }
}

public enum ProjectWorkspaceError: Error, LocalizedError, Equatable {
    case invalidRoot(String)
    case invalidManifest(String)
    case unsupportedSchema(Int)
    case unsafePath(String, String)
    case ambiguousProject([String])
    case conflictingFile(String)

    public var errorDescription: String? {
        switch self {
        case .invalidRoot(let value): "invalid project root: \(value)"
        case .invalidManifest(let value): "invalid project manifest: \(value)"
        case .unsupportedSchema(let value): "unsupported project manifest schema: \(value)"
        case .unsafePath(let field, let value): "unsafe \(field) path: \(value)"
        case .ambiguousProject(let values): "ambiguous project setup: \(values.joined(separator: ", "))"
        case .conflictingFile(let value): "setup would overwrite conflicting file: \(value)"
        }
    }
}
