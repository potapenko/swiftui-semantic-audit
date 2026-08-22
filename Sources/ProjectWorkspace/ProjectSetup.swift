import Foundation

public struct ProjectSetupOptions: Sendable {
    public let sourceRoot: String?
    public let container: String?
    public let scheme: String?
    public let platform: String?

    public init(sourceRoot: String? = nil, container: String? = nil, scheme: String? = nil, platform: String? = nil) {
        self.sourceRoot = sourceRoot
        self.container = container
        self.scheme = scheme
        self.platform = platform
    }
}

public struct ProjectSetupPlan: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let projectRoot: String
    public let manifestPath: String
    public let runtimeRoot: String
    public let projectType: String
    public let manifest: ProjectManifest?
    public let writes: [String]
    public let blockers: [String]
    public let applied: Bool

    public init(
        projectRoot: String,
        manifestPath: String,
        runtimeRoot: String,
        projectType: String,
        manifest: ProjectManifest?,
        writes: [String],
        blockers: [String],
        applied: Bool = false
    ) {
        self.schemaVersion = 1
        self.projectRoot = projectRoot
        self.manifestPath = manifestPath
        self.runtimeRoot = runtimeRoot
        self.projectType = projectType
        self.manifest = manifest
        self.writes = writes.sorted()
        self.blockers = blockers.sorted()
        self.applied = applied
    }

    public var ready: Bool { blockers.isEmpty && manifest != nil }

    public func jsonData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        var data = try encoder.encode(self)
        data.append(0x0A)
        return data
    }
}

public struct ProjectSetupPlanner: Sendable {
    public init() {}

    public func plan(
        projectRoot requestedRoot: URL,
        options: ProjectSetupOptions = .init(),
        applicationSupportRoot: URL? = nil
    ) throws -> ProjectSetupPlan {
        let root = requestedRoot.standardizedFileURL.resolvingSymlinksInPath()
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: root.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            throw ProjectWorkspaceError.invalidRoot(root.path)
        }
        let locations = ProjectRuntimeLocations(projectRoot: root, applicationSupportRoot: applicationSupportRoot)
        let manifestURL = root.appendingPathComponent(".swiftui-audit/project.json")
        if FileManager.default.fileExists(atPath: manifestURL.path) {
            let manifest = try ProjectManifest.load(projectRoot: root)
            let writes = FileManager.default.fileExists(atPath: locations.root.path)
                ? [] : [locations.root.path]
            return ProjectSetupPlan(
                projectRoot: root.path,
                manifestPath: manifestURL.path,
                runtimeRoot: locations.root.path,
                projectType: manifest.build.kind.rawValue,
                manifest: manifest,
                writes: writes,
                blockers: []
            )
        }

        let sourceRoot = options.sourceRoot ?? defaultSourceRoot(root)
        let config = FileManager.default.fileExists(atPath: root.appendingPathComponent(".swiftui-audit.json").path)
            ? ".swiftui-audit.json" : nil
        let proposed: ProjectManifest?
        var blockers: [String] = []
        if sourceRoot == nil { blockers.append("provide --source-root for the analyzed Swift sources") }
        let projectType: String
        if FileManager.default.fileExists(atPath: root.appendingPathComponent("Package.swift").path) {
            projectType = "swiftpm"
            proposed = sourceRoot.map {
                ProjectManifest(
                    sourceRoot: $0,
                    analysisConfiguration: config,
                    build: ProjectBuildConfiguration(kind: .swiftPM)
                )
            }
        } else {
            let containers = discoverContainers(root: root)
            let container = options.container ?? (containers.count == 1 ? containers[0] : nil)
            let schemes = discoverSchemes(root: root)
            let scheme = options.scheme ?? (schemes.count == 1 ? schemes[0] : nil)
            if container == nil { blockers.append("select exactly one Xcode container: \(containers.joined(separator: ", "))") }
            if scheme == nil { blockers.append("select exactly one shared Xcode scheme: \(schemes.joined(separator: ", "))") }
            if options.platform == nil { blockers.append("provide --platform, for example macOS or iOS Simulator") }
            projectType = containers.isEmpty ? "source-directory" : "xcode"
            if let sourceRoot, let container, let scheme, let platform = options.platform {
                proposed = ProjectManifest(
                    sourceRoot: sourceRoot,
                    analysisConfiguration: config,
                    build: ProjectBuildConfiguration(
                        kind: .xcode, container: container, scheme: scheme, platform: platform
                    )
                )
            } else {
                proposed = nil
            }
        }
        try proposed?.validate(projectRoot: root)
        return ProjectSetupPlan(
            projectRoot: root.path,
            manifestPath: manifestURL.path,
            runtimeRoot: locations.root.path,
            projectType: projectType,
            manifest: proposed,
            writes: proposed == nil ? [] : [manifestURL.path, locations.root.path],
            blockers: blockers
        )
    }

    public func apply(_ plan: ProjectSetupPlan) throws -> ProjectSetupPlan {
        guard plan.ready, let manifest = plan.manifest else {
            throw ProjectWorkspaceError.ambiguousProject(plan.blockers)
        }
        let root = URL(fileURLWithPath: plan.projectRoot, isDirectory: true)
        try manifest.validate(projectRoot: root)
        let manifestURL = URL(fileURLWithPath: plan.manifestPath)
        let data = try manifest.canonicalData()
        if FileManager.default.fileExists(atPath: manifestURL.path) {
            guard try Data(contentsOf: manifestURL) == data else {
                throw ProjectWorkspaceError.conflictingFile(manifestURL.path)
            }
        } else {
            try FileManager.default.createDirectory(
                at: manifestURL.deletingLastPathComponent(), withIntermediateDirectories: true
            )
            try data.write(to: manifestURL, options: .atomic)
        }
        try FileManager.default.createDirectory(
            at: URL(fileURLWithPath: plan.runtimeRoot, isDirectory: true), withIntermediateDirectories: true
        )
        return ProjectSetupPlan(
            projectRoot: plan.projectRoot,
            manifestPath: plan.manifestPath,
            runtimeRoot: plan.runtimeRoot,
            projectType: plan.projectType,
            manifest: manifest,
            writes: plan.writes,
            blockers: [],
            applied: true
        )
    }

    private func defaultSourceRoot(_ root: URL) -> String? {
        FileManager.default.fileExists(atPath: root.appendingPathComponent("Sources").path) ? "Sources" : nil
    }

    private func discoverContainers(root: URL) -> [String] {
        guard let entries = try? FileManager.default.contentsOfDirectory(atPath: root.path) else { return [] }
        return entries.filter { $0.hasSuffix(".xcworkspace") || $0.hasSuffix(".xcodeproj") }.sorted()
    }

    private func discoverSchemes(root: URL) -> [String] {
        let enumerator = FileManager.default.enumerator(
            at: root, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]
        )
        return Array(Set((enumerator?.compactMap { $0 as? URL }.filter {
            $0.pathExtension == "xcscheme" && $0.path.contains("xcshareddata/xcschemes")
        }.map { $0.deletingPathExtension().lastPathComponent }) ?? [])).sorted()
    }
}
