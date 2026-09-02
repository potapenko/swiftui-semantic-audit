import Foundation

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

struct CacheMaintenanceReport: Equatable {
    var ran = false
    var removedArtifacts = 0
    var removedDatabases = 0
    var removedLegacy = false
    var skippedBusyDatabases = 0
    var remainingBytes: Int64 = 0
}

extension AnalysisCacheStore {
    static let maintenanceInterval: TimeInterval = 24 * 60 * 60
    static let legacyGraceInterval: TimeInterval = 7 * 24 * 60 * 60

    func performMaintenance(
        now: Date = Date(),
        force: Bool = false,
        maximumBytes: Int64 = Self.maximumSizeBytes,
        targetBytes: Int64 = Self.targetSizeBytes,
        protecting protectedURLs: Set<URL> = []
    ) throws -> CacheMaintenanceReport {
        precondition(maximumBytes > 0 && targetBytes >= 0 && targetBytes <= maximumBytes)
        try FileManager.default.createDirectory(at: cacheRootURL, withIntermediateDirectories: true)
        let globalLock = cacheRootURL.appendingPathComponent(".maintenance.lock")
        return try withNonblockingLock(at: globalLock) {
            let marker = versionDirectoryURL.appendingPathComponent(".last-maintenance")
            if !force, let lastRun = modificationDate(of: marker),
               now.timeIntervalSince(lastRun) < Self.maintenanceInterval {
                return CacheMaintenanceReport()
            }

            var report = CacheMaintenanceReport(ran: true)
            try? pruneAllIndexedGraphHistories()
            report.removedLegacy = removeLegacyCacheIfEligible(now: now)

            var remaining = allocatedBytes(at: versionDirectoryURL)
            if remaining > maximumBytes {
                let protected = Set(protectedURLs.map { $0.standardizedFileURL.path })
                for candidate in evictionCandidates().sorted(by: CacheEvictionCandidate.oldestFirst) {
                    guard remaining > targetBytes else { break }
                    guard !protected.contains(candidate.url.standardizedFileURL.path) else { continue }
                    switch candidate.kind {
                    case .artifact:
                        do {
                            try FileManager.default.removeItem(at: candidate.url)
                            remaining = max(0, remaining - candidate.allocatedBytes)
                            report.removedArtifacts += 1
                        } catch {
                            continue
                        }
                    case .database:
                        let lock = candidate.url.appendingPathExtension("lock")
                        let removed = (try? withNonblockingLock(at: lock) {
                            try FileManager.default.removeItem(at: candidate.url)
                            try? FileManager.default.removeItem(at: candidate.url.appendingPathExtension("access"))
                            return true
                        }) ?? false
                        if removed {
                            remaining = max(0, remaining - candidate.allocatedBytes)
                            report.removedDatabases += 1
                        } else {
                            report.skippedBusyDatabases += 1
                        }
                    }
                }
            }
            report.remainingBytes = allocatedBytes(at: versionDirectoryURL)
            try? touch(marker, at: now)
            return report
        } ?? CacheMaintenanceReport()
    }

    private func pruneAllIndexedGraphHistories() throws {
        let scopes = versionDirectoryURL.appendingPathComponent("scopes", isDirectory: true)
        guard let enumerator = FileManager.default.enumerator(
            at: scopes,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return }
        for case let directory as URL in enumerator where directory.lastPathComponent == "indexed" {
            enumerator.skipDescendants()
            let files = (try? FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey],
                options: [.skipsHiddenFiles]
            ))?.filter {
                $0.pathExtension == "json" &&
                    (try? $0.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true
            }.sorted {
                let lhs = modificationDate(of: $0) ?? .distantPast
                let rhs = modificationDate(of: $1) ?? .distantPast
                return (lhs, $0.lastPathComponent) > (rhs, $1.lastPathComponent)
            } ?? []
            for file in files.dropFirst(Self.indexedGraphRetentionCount) {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }

    private func evictionCandidates() -> [CacheEvictionCandidate] {
        var result: [CacheEvictionCandidate] = []
        let scopes = versionDirectoryURL.appendingPathComponent("scopes", isDirectory: true)
        if let enumerator = FileManager.default.enumerator(
            at: scopes,
            includingPropertiesForKeys: [.isRegularFileKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) {
            for case let file as URL in enumerator where file.pathExtension == "json" {
                let parent = file.deletingLastPathComponent().lastPathComponent
                let isEvictableArtifact = parent == "indexed" || parent == "indexed_files" ||
                    file.lastPathComponent == "frontend.json"
                guard isEvictableArtifact,
                      (try? file.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true
                else { continue }
                result.append(CacheEvictionCandidate(
                    url: file,
                    lastAccess: modificationDate(of: file) ?? .distantPast,
                    allocatedBytes: allocatedBytes(at: file),
                    kind: .artifact
                ))
            }
        }

        if let databases = try? FileManager.default.contentsOfDirectory(
            at: sharedIndexStoreRootURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) {
            for database in databases where database.pathExtension.isEmpty {
                guard (try? database.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true else { continue }
                result.append(CacheEvictionCandidate(
                    url: database,
                    lastAccess: modificationDate(of: database.appendingPathExtension("access"))
                        ?? newestModificationDate(at: database),
                    allocatedBytes: allocatedBytes(at: database),
                    kind: .database
                ))
            }
        }
        return result
    }

    private func removeLegacyCacheIfEligible(now: Date) -> Bool {
        let firstSuccess = versionDirectoryURL.appendingPathComponent(".first-success")
        let legacy = cacheRootURL.appendingPathComponent("v1", isDirectory: true)
        let cutoff = now.addingTimeInterval(-Self.legacyGraceInterval)
        guard let firstSuccessDate = modificationDate(of: firstSuccess), firstSuccessDate <= cutoff,
              FileManager.default.fileExists(atPath: legacy.path),
              newestLegacyActivityDate(at: legacy) <= cutoff
        else { return false }

        let locks = legacyDatabaseLocks(at: legacy)
        var descriptors: [Int32] = []
        for lock in locks {
            guard let descriptor = acquireLock(at: lock) else {
                descriptors.forEach(releaseLock)
                return false
            }
            descriptors.append(descriptor)
        }
        defer { descriptors.forEach(releaseLock) }
        do {
            try FileManager.default.removeItem(at: legacy)
            return true
        } catch {
            return false
        }
    }

    private func legacyDatabaseLocks(at legacy: URL) -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: legacy, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]
        ) else { return [] }
        return enumerator.compactMap { $0 as? URL }
            .filter { $0.pathExtension == "lock" }
            .sorted { $0.path < $1.path }
    }

    private func withNonblockingLock<Value>(at url: URL, operation: () throws -> Value) throws -> Value? {
        guard let descriptor = acquireLock(at: url) else { return nil }
        defer { releaseLock(descriptor) }
        return try operation()
    }

    private func acquireLock(at url: URL) -> Int32? {
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        let descriptor = open(url.path, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)
        guard descriptor >= 0 else { return nil }
        guard flock(descriptor, LOCK_EX | LOCK_NB) == 0 else {
            close(descriptor)
            return nil
        }
        return descriptor
    }

    private func releaseLock(_ descriptor: Int32) {
        _ = flock(descriptor, LOCK_UN)
        close(descriptor)
    }

    private func modificationDate(of url: URL) -> Date? {
        try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
    }

    private func newestModificationDate(at root: URL) -> Date {
        var newest = modificationDate(of: root) ?? .distantPast
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return newest }
        for case let url as URL in enumerator {
            if let date = modificationDate(of: url), date > newest { newest = date }
        }
        return newest
    }

    private func newestLegacyActivityDate(at root: URL) -> Date {
        var newest = Date.distantPast
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [
                .isRegularFileKey, .contentAccessDateKey, .contentModificationDateKey,
            ],
            options: [.skipsHiddenFiles]
        ) else { return newest }
        for case let url as URL in enumerator {
            guard let values = try? url.resourceValues(forKeys: [
                .isRegularFileKey, .contentAccessDateKey, .contentModificationDateKey,
            ]), values.isRegularFile == true else { continue }
            if let date = values.contentAccessDate, date > newest { newest = date }
            if let date = values.contentModificationDate, date > newest { newest = date }
        }
        return newest
    }

    private func allocatedBytes(at root: URL) -> Int64 {
        var total = allocatedBytesForFile(at: root)
        guard let values = try? root.resourceValues(forKeys: [.isDirectoryKey]), values.isDirectory == true,
              let enumerator = FileManager.default.enumerator(
                at: root,
                includingPropertiesForKeys: [.isRegularFileKey, .fileAllocatedSizeKey, .totalFileAllocatedSizeKey],
                options: [.skipsHiddenFiles]
              )
        else { return total }
        for case let url as URL in enumerator { total += allocatedBytesForFile(at: url) }
        return total
    }

    private func allocatedBytesForFile(at url: URL) -> Int64 {
        guard let values = try? url.resourceValues(forKeys: [
            .isRegularFileKey, .fileAllocatedSizeKey, .totalFileAllocatedSizeKey, .fileSizeKey,
        ]), values.isRegularFile == true else { return 0 }
        return Int64(values.totalFileAllocatedSize ?? values.fileAllocatedSize ?? values.fileSize ?? 0)
    }
}

private struct CacheEvictionCandidate {
    enum Kind { case artifact, database }

    let url: URL
    let lastAccess: Date
    let allocatedBytes: Int64
    let kind: Kind

    static func oldestFirst(_ lhs: Self, _ rhs: Self) -> Bool {
        (lhs.lastAccess, lhs.url.path) < (rhs.lastAccess, rhs.url.path)
    }
}
