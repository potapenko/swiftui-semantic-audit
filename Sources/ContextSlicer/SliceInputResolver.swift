import Foundation
import SnapshotStore

public enum SliceInput: Equatable, Sendable {
    case snapshot(URL)
    case source(URL)
}

public struct SliceInputResolver: Sendable {
    public init() {}

    public func resolve(input: String?, currentDirectory: URL) throws -> SliceInput {
        let fileManager = FileManager.default
        if let input {
            let url = SnapshotPathPolicy.canonicalURL(Self.resolvePath(input, relativeTo: currentDirectory))
            return try classifyExplicit(url, fileManager: fileManager)
        }
        let source = SnapshotPathPolicy.canonicalURL(currentDirectory)
        let defaultSnapshot = SnapshotPathPolicy.canonicalURL(
            currentDirectory.appendingPathComponent(".semantic", isDirectory: true)
        )
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: defaultSnapshot.path, isDirectory: &isDirectory), isDirectory.boolValue {
            let names = Set(try fileManager.contentsOfDirectory(atPath: defaultSnapshot.path))
            let required = Set(SnapshotWriter.requiredFiles)
            if required.isSubset(of: names) {
                _ = try SnapshotReader().read(from: defaultSnapshot)
                return .snapshot(defaultSnapshot)
            }
            let present = names.intersection(required)
            if !present.isEmpty {
                throw SnapshotError.incompleteSnapshot(Array(required.subtracting(present)).sorted())
            }
        }
        return .source(source)
    }

    private func classifyExplicit(_ url: URL, fileManager: FileManager) throws -> SliceInput {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            return .source(url)
        }
        let names = Set(try fileManager.contentsOfDirectory(atPath: url.path))
        let required = Set(SnapshotWriter.requiredFiles)
        if required.isSubset(of: names) {
            _ = try SnapshotReader().read(from: url)
            return .snapshot(url)
        }
        let present = names.intersection(required)
        if !present.isEmpty, !containsSwiftSource(url, fileManager: fileManager) {
            throw SnapshotError.incompleteSnapshot(Array(required.subtracting(present)).sorted())
        }
        return .source(url)
    }

    private func containsSwiftSource(_ directory: URL, fileManager: FileManager) -> Bool {
        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return false }
        for case let file as URL in enumerator where file.pathExtension == "swift" {
            if (try? file.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true { return true }
        }
        return false
    }

    private static func resolvePath(_ path: String, relativeTo currentDirectory: URL) -> URL {
        if path.hasPrefix("/") { return URL(fileURLWithPath: path) }
        return currentDirectory.appendingPathComponent(path)
    }
}
