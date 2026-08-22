import AuditCore
import Foundation

public enum ProjectServiceState: String, Codable, Sendable {
    case stopped
    case starting
    case syntaxReady = "syntax-ready"
    case buildingIndex = "building-index"
    case indexedReady = "indexed-ready"
    case failed
}

public struct ProjectDiffSummary: Codable, Equatable, Sendable {
    public let changes: Int
    public let newFindings: Int
    public let resolvedFindings: Int

    public init(changes: Int, newFindings: Int, resolvedFindings: Int) {
        self.changes = changes
        self.newFindings = newFindings
        self.resolvedFindings = resolvedFindings
    }
}

public struct ProjectStatus: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1

    public let schemaVersion: Int
    public let toolVersion: String
    public let projectID: String
    public let serviceState: ProjectServiceState
    public let generation: Int
    public let workspaceDigest: String
    public let indexedWorkspaceDigest: String?
    public let fresh: Bool
    public let resolution: String?
    public let indexStorePath: String?
    public let configurationDigest: String?
    public let liveSnapshotPath: String?
    public let baselinePath: String
    public let baselineCompatible: Bool?
    public let diff: ProjectDiffSummary?
    public let lastError: String?

    public init(
        projectID: String,
        serviceState: ProjectServiceState,
        generation: Int,
        workspaceDigest: String,
        indexedWorkspaceDigest: String? = nil,
        fresh: Bool = false,
        resolution: String? = nil,
        indexStorePath: String? = nil,
        configurationDigest: String? = nil,
        liveSnapshotPath: String? = nil,
        baselinePath: String,
        baselineCompatible: Bool? = nil,
        diff: ProjectDiffSummary? = nil,
        lastError: String? = nil
    ) {
        self.schemaVersion = Self.currentSchemaVersion
        self.toolVersion = ToolMetadata.version
        self.projectID = projectID
        self.serviceState = serviceState
        self.generation = generation
        self.workspaceDigest = workspaceDigest
        self.indexedWorkspaceDigest = indexedWorkspaceDigest
        self.fresh = fresh
        self.resolution = resolution
        self.indexStorePath = indexStorePath
        self.configurationDigest = configurationDigest
        self.liveSnapshotPath = liveSnapshotPath
        self.baselinePath = baselinePath
        self.baselineCompatible = baselineCompatible
        self.diff = diff
        self.lastError = lastError
    }

    public func jsonData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        var data = try encoder.encode(self)
        data.append(0x0A)
        return data
    }
}

public struct ProjectStatusStore: Sendable {
    public init() {}

    public func load(from url: URL) -> ProjectStatus? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(ProjectStatus.self, from: data)
    }

    public func save(_ status: ProjectStatus, to url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try status.jsonData().write(to: url, options: .atomic)
    }
}
