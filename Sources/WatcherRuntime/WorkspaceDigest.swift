import CryptoKit
import Foundation
import ProjectWorkspace

public enum WorkspaceDigest {
    public static func compute(projectRoot: URL, manifest: ProjectManifest) throws -> String {
        let root = projectRoot.standardizedFileURL.resolvingSymlinksInPath()
        let source = manifest.sourceURL(projectRoot: root).standardizedFileURL.resolvingSymlinksInPath()
        var files = swiftFiles(at: source)
        files.append(root.appendingPathComponent(".swiftui-audit/project.json"))
        for name in ["Package.swift", "Package.resolved"] {
            let candidate = root.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: candidate.path) { files.append(candidate) }
        }
        if let container = manifest.build.container {
            files.append(contentsOf: regularFiles(at: root.appendingPathComponent(container)))
        }
        if let configuration = manifest.configurationURL(projectRoot: root),
           FileManager.default.fileExists(atPath: configuration.path) {
            files.append(configuration)
        }
        let rootPrefix = root.path.hasSuffix("/") ? root.path : root.path + "/"
        var data = Data()
        for file in Array(Set(files.map(\.standardizedFileURL))).sorted(by: { $0.path < $1.path }) {
            let path = file.path.hasPrefix(rootPrefix) ? String(file.path.dropFirst(rootPrefix.count)) : file.path
            data.append(Data(path.utf8))
            data.append(0)
            data.append(try Data(contentsOf: file))
            data.append(0)
        }
        return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private static func swiftFiles(at root: URL) -> [URL] {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: root.path, isDirectory: &isDirectory) else { return [] }
        if !isDirectory.boolValue { return root.pathExtension.lowercased() == "swift" ? [root] : [] }
        let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        )
        return (enumerator?.compactMap { $0 as? URL }.filter {
            $0.pathExtension.lowercased() == "swift" &&
                (try? $0.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true
        } ?? []).sorted { $0.path < $1.path }
    }

    private static func regularFiles(at root: URL) -> [URL] {
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: root.path, isDirectory: &isDirectory) else { return [] }
        if !isDirectory.boolValue { return [root] }
        let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        )
        return (enumerator?.compactMap { $0 as? URL }.filter {
            (try? $0.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true
        } ?? []).sorted { $0.path < $1.path }
    }
}
