import Foundation

public struct SnapshotLocations: Equatable, Sendable {
    public let source: URL
    public let output: URL

    public init(source: URL, output: URL) {
        self.source = source
        self.output = output
    }
}

public enum SnapshotPathPolicy {
    public static func validate(sourceURL: URL, outputURL: URL) throws -> SnapshotLocations {
        let source = canonicalURL(sourceURL)
        let output = canonicalURL(outputURL)
        guard output.path != "/", !output.lastPathComponent.isEmpty else {
            throw SnapshotError.unsafeOutputPath(output.path)
        }
        if source.path == output.path || source.path.hasPrefix(directoryPrefix(output.path)) {
            throw SnapshotError.sourceOutputOverlap(source: source.path, output: output.path)
        }
        return SnapshotLocations(source: source, output: output)
    }

    public static func canonicalURL(_ url: URL) -> URL {
        let standardized = url.standardizedFileURL
        let fileManager = FileManager.default
        var existing = standardized
        var missingComponents: [String] = []
        while !fileManager.fileExists(atPath: existing.path), existing.path != "/" {
            missingComponents.insert(existing.lastPathComponent, at: 0)
            existing.deleteLastPathComponent()
        }
        var resolved = existing.resolvingSymlinksInPath().standardizedFileURL
        for component in missingComponents {
            resolved.appendPathComponent(component)
        }
        return resolved.standardizedFileURL
    }

    private static func directoryPrefix(_ path: String) -> String {
        path.hasSuffix("/") ? path : path + "/"
    }
}
