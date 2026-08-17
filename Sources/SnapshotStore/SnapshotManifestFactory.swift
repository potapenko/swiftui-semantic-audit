import AuditCore
import Foundation

public enum SnapshotManifestFactory {
    public static func make(sourcePath: String, toolVersion: String = "0.1.0") -> SnapshotManifest {
        let sourceURL = URL(fileURLWithPath: sourcePath).standardizedFileURL
        let workingURL = sourceURL.hasDirectoryPath ? sourceURL : sourceURL.deletingLastPathComponent()
        let repositoryRoot = command("git", ["-C", workingURL.path, "rev-parse", "--show-toplevel"])
            .map { URL(fileURLWithPath: $0).standardizedFileURL }
        let revision = command("git", ["-C", workingURL.path, "rev-parse", "HEAD"]) ?? "unavailable"
        let swiftVersion = command("swift", ["--version"])?
            .replacingOccurrences(of: "\n", with: " ") ?? "unavailable"

        return SnapshotManifest(
            toolVersion: toolVersion,
            swiftVersion: swiftVersion,
            repositoryRevision: revision,
            generatedFrom: generatedFrom(sourcePath: sourcePath, sourceURL: sourceURL, repositoryRoot: repositoryRoot)
        )
    }

    private static func generatedFrom(sourcePath: String, sourceURL: URL, repositoryRoot: URL?) -> String {
        if let repositoryRoot {
            let root = repositoryRoot.path.hasSuffix("/") ? repositoryRoot.path : repositoryRoot.path + "/"
            if sourceURL.path == repositoryRoot.path { return "." }
            if sourceURL.path.hasPrefix(root) {
                return String(sourceURL.path.dropFirst(root.count)).replacingOccurrences(of: "\\", with: "/")
            }
        }
        if !sourcePath.hasPrefix("/") {
            let normalized = NSString(string: sourcePath).standardizingPath
            return normalized.isEmpty ? "." : normalized.replacingOccurrences(of: "\\", with: "/")
        }
        return sourceURL.lastPathComponent.isEmpty ? "." : sourceURL.lastPathComponent
    }

    private static func command(_ command: String, _ arguments: [String]) -> String? {
        guard let result = try? BoundedProcessRunner().run(
            command,
            arguments: arguments,
            timeout: 5
        ), result.status == 0 else { return nil }
        let value = result.outputString.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
