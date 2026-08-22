import Darwin
import Foundation

public enum ProjectLockError: Error, LocalizedError {
    case unavailable(String)

    public var errorDescription: String? {
        switch self { case .unavailable(let path): "another watcher owns the project lock: \(path)" }
    }
}

public final class ProjectLock: @unchecked Sendable {
    private let descriptor: Int32

    public init(url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        descriptor = open(url.path, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)
        guard descriptor >= 0, flock(descriptor, LOCK_EX | LOCK_NB) == 0 else {
            if descriptor >= 0 { close(descriptor) }
            throw ProjectLockError.unavailable(url.path)
        }
    }

    deinit {
        flock(descriptor, LOCK_UN)
        close(descriptor)
    }
}
