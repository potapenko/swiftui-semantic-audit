import CryptoKit
import Darwin
import Foundation

/// Validation identity, never a canonical semantic fact or a compiler content attestation.
struct IndexSourceState: Equatable {
    let files: [URL]
    let latestChanges: [String: Date]
    let digest: String

    init(root: URL) throws {
        let manager = FileManager.default
        var directory: ObjCBool = false
        guard manager.fileExists(atPath: root.path, isDirectory: &directory) else {
            throw IndexResolutionError.changedInputs
        }
        let candidates: [URL]
        if directory.boolValue {
            candidates = manager.enumerator(
                at: root, includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            )?.compactMap { $0 as? URL } ?? []
        } else {
            candidates = [root]
        }
        files = Array(Set(try candidates.filter {
            guard $0.pathExtension.lowercased() == "swift" else { return false }
            return try $0.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile == true
        }.map { $0.standardizedFileURL.resolvingSymlinksInPath() })).sorted { $0.path < $1.path }
        var changes: [String: Date] = [:]
        var identity = Data()
        for file in files {
            var status = stat()
            guard stat(file.path, &status) == 0 else { throw IndexResolutionError.changedInputs }
            let modified = Double(status.st_mtimespec.tv_sec) + Double(status.st_mtimespec.tv_nsec) / 1e9
            let changed = Double(status.st_ctimespec.tv_sec) + Double(status.st_ctimespec.tv_nsec) / 1e9
            changes[file.path] = Date(timeIntervalSince1970: max(modified, changed))
            identity.append(Data(file.path.utf8))
            identity.append(0)
            identity.append(contentsOf: SHA256.hash(data: try Data(contentsOf: file)))
            identity.append(Data("|\(status.st_mtimespec.tv_sec):\(status.st_mtimespec.tv_nsec)|\(status.st_ctimespec.tv_sec):\(status.st_ctimespec.tv_nsec)|".utf8))
        }
        latestChanges = changes
        digest = SHA256.hash(data: identity).map { String(format: "%02x", $0) }.joined()
    }
}
