import AuditCore
import CryptoKit
import Foundation

public struct ProjectRuntimeLocations: Equatable, Sendable {
    public let projectID: String
    public let root: URL
    public let liveSnapshot: URL
    public let previewSnapshot: URL
    public let status: URL
    public let lock: URL
    public let servicePlist: URL
    public let stdoutLog: URL
    public let stderrLog: URL

    public init(projectRoot: URL, applicationSupportRoot: URL? = nil) {
        let canonical = projectRoot.standardizedFileURL.resolvingSymlinksInPath().path
        projectID = SHA256.hash(data: Data(canonical.utf8)).prefix(16)
            .map { String(format: "%02x", $0) }.joined()
        let support = applicationSupportRoot
            ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        root = support.appendingPathComponent("swiftui-audit/projects/\(projectID)", isDirectory: true)
        liveSnapshot = root.appendingPathComponent("live", isDirectory: true)
        previewSnapshot = root.appendingPathComponent("preview", isDirectory: true)
        status = root.appendingPathComponent("status.json")
        lock = root.appendingPathComponent("watcher.lock")
        servicePlist = root.appendingPathComponent("service.plist")
        stdoutLog = root.appendingPathComponent("watcher.log")
        stderrLog = root.appendingPathComponent("watcher.error.log")
    }
}
