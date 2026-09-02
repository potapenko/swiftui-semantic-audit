@testable import AnalysisCache
import AuditCore
import Foundation
import SwiftSyntaxFrontend
import XCTest
#if canImport(Darwin)
import Darwin
#endif

final class IncrementalGraphScannerTests: XCTestCase {
    func testParallelFrontendMatchesSerialBytes() throws {
        let fixture = try makeFixture()
        defer { try? FileManager.default.removeItem(at: fixture) }
        for index in 0..<12 {
            try write(
                """
                import SwiftUI
                struct Feature\(index): View {
                    @State private var count = \(index)
                    var body: some View {
                        Button("Count \\(count)") { count += 1 }
                            .onChange(of: count) { _, value in count = value }
                    }
                }
                """,
                to: fixture.appendingPathComponent("Feature\(index).swift")
            )
        }

        let serial = try GraphScanner(maximumParallelism: 1).scan(path: fixture.path).jsonData()
        for _ in 0..<4 {
            let parallel = try GraphScanner(maximumParallelism: 4).scan(path: fixture.path).jsonData()
            XCTAssertEqual(parallel, serial)
        }
    }

    func testWarmCacheReusesEveryFileAndMatchesFullRebuild() throws {
        let fixture = try makeFixture()
        defer { try? FileManager.default.removeItem(at: fixture) }

        let scanner = GraphScanner()
        let cold = try scanner.scan(path: fixture.path, previousState: nil)
        let warm = try scanner.scan(path: fixture.path, previousState: cold.state)
        let full = try scanner.scan(path: fixture.path)

        XCTAssertEqual(warm.statistics.parsedFiles, [])
        XCTAssertEqual(warm.statistics.reusedFiles, ["Model.swift", "Screen.swift"])
        XCTAssertEqual(try warm.graph.jsonData(), try full.jsonData())
    }

    func testBodyEditReparsesOnlyChangedFileAndDependencyEditInvalidatesConsumer() throws {
        let fixture = try makeFixture()
        defer { try? FileManager.default.removeItem(at: fixture) }
        let scanner = GraphScanner()
        let cold = try scanner.scan(path: fixture.path, previousState: nil)

        try write(
            """
            import SwiftUI
            struct Screen: View {
                @State private var model = Model()
                var body: some View { Text("value: \\(model.value)") }
            }
            """,
            to: fixture.appendingPathComponent("Screen.swift")
        )
        let bodyEdit = try scanner.scan(path: fixture.path, previousState: cold.state)
        XCTAssertEqual(bodyEdit.statistics.parsedFiles, ["Screen.swift"])
        XCTAssertEqual(try bodyEdit.graph.jsonData(), try scanner.scan(path: fixture.path).jsonData())

        try write(
            """
            struct Model {
                var value = 1
                var enabled = true
            }
            """,
            to: fixture.appendingPathComponent("Model.swift")
        )
        let dependencyEdit = try scanner.scan(path: fixture.path, previousState: bodyEdit.state)
        XCTAssertEqual(dependencyEdit.statistics.parsedFiles, ["Model.swift", "Screen.swift"])
        XCTAssertEqual(dependencyEdit.statistics.invalidatedDependents, ["Screen.swift"])
        XCTAssertEqual(try dependencyEdit.graph.jsonData(), try scanner.scan(path: fixture.path).jsonData())
    }

    func testPersistentStateRoundTripsAndCorruptionIsAMiss() throws {
        let fixture = try makeFixture()
        let cacheRoot = fixture.appendingPathComponent("Cache", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: fixture) }
        let scanner = GraphScanner()
        let cold = try scanner.scan(path: fixture.path, previousState: nil)
        let cache = AnalysisCacheStore(rootDirectory: cacheRoot, sourceRoot: fixture)

        try cache.saveFrontendState(cold.state)
        XCTAssertEqual(cache.loadFrontendState(), cold.state)

        DispatchQueue.concurrentPerform(iterations: 8) { _ in
            try? cache.saveFrontendState(cold.state)
        }
        XCTAssertEqual(cache.loadFrontendState(), cold.state)

        let cacheFiles = FileManager.default.enumerator(at: cacheRoot, includingPropertiesForKeys: nil)?
            .compactMap { $0 as? URL }.filter { $0.lastPathComponent == "frontend.json" } ?? []
        XCTAssertEqual(cacheFiles.count, 1)
        try Data("not-json".utf8).write(to: cacheFiles[0], options: .atomic)
        XCTAssertNil(cache.loadFrontendState())
    }

    func testCacheSchemaTwoLayoutAndWholeGraphRetention() throws {
        let fixture = try makeFixture()
        let cacheRoot = fixture.appendingPathComponent("Cache", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: fixture) }
        let cache = AnalysisCacheStore(rootDirectory: cacheRoot, sourceRoot: fixture)

        XCTAssertEqual(AnalysisCacheStore.schemaVersion, 2)
        XCTAssertEqual(cache.versionDirectoryURL.lastPathComponent, "v2")
        XCTAssertEqual(cache.projectDirectoryURL.deletingLastPathComponent().lastPathComponent, "scopes")
        XCTAssertTrue(cache.sharedIndexStoreRootURL.path.contains("/v2/shared/indexstoredb"))
        let siblingScope = AnalysisCacheStore(
            rootDirectory: cacheRoot,
            sourceRoot: fixture.appendingPathComponent("Screen.swift")
        )
        XCTAssertNotEqual(siblingScope.projectDirectoryURL, cache.projectDirectoryURL)
        XCTAssertEqual(siblingScope.sharedIndexStoreRootURL, cache.sharedIndexStoreRootURL)
        XCTAssertEqual(
            siblingScope.sharedIndexStoreDatabaseURL(identityData: Data("same-compiler".utf8)),
            cache.sharedIndexStoreDatabaseURL(identityData: Data("same-compiler".utf8))
        )

        for index in 0..<3 {
            try cache.saveIndexedGraph(
                SemanticGraph(configurationDigest: "retention-\(index)", nodes: [], edges: []),
                key: "graph-\(index)"
            )
        }
        let indexed = cache.projectDirectoryURL.appendingPathComponent("indexed", isDirectory: true)
        let files = try FileManager.default.contentsOfDirectory(at: indexed, includingPropertiesForKeys: nil)
        XCTAssertEqual(files.filter { $0.pathExtension == "json" }.count, 2)
        XCTAssertNotNil(cache.loadIndexedGraph(key: "graph-2"))
    }

    func testMaintenanceEvictsLeastRecentlyUsedArtifactsToTarget() throws {
        let fixture = try makeFixture()
        let cacheRoot = fixture.appendingPathComponent("Cache", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: fixture) }
        let cache = AnalysisCacheStore(rootDirectory: cacheRoot, sourceRoot: fixture)
        let payload = [UInt8](repeating: 7, count: 32_768)
        try cache.saveArtifact(payload, namespace: "indexed_files", key: "old")
        try cache.saveArtifact(payload, namespace: "indexed_files", key: "new")
        let directory = cache.projectDirectoryURL.appendingPathComponent("indexed_files", isDirectory: true)
        let oldURL = directory.appendingPathComponent("old.json")
        let newURL = directory.appendingPathComponent("new.json")
        let oldDate = Date(timeIntervalSinceNow: -10_000)
        try FileManager.default.setAttributes([.modificationDate: oldDate], ofItemAtPath: oldURL.path)

        let report = try cache.performMaintenance(
            force: true,
            maximumBytes: 100_000,
            targetBytes: 85_000
        )

        XCTAssertTrue(report.ran)
        XCTAssertGreaterThanOrEqual(report.removedArtifacts, 1)
        XCTAssertNil(cache.loadArtifact([UInt8].self, namespace: "indexed_files", key: "old"))
        XCTAssertNotNil(cache.loadArtifact([UInt8].self, namespace: "indexed_files", key: "new"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: newURL.path))
        XCTAssertFalse(try cache.performMaintenance().ran)
    }

    func testMaintenanceCanEvictFrontendStateAsRecoverableCacheMiss() throws {
        let fixture = try makeFixture()
        let cacheRoot = fixture.appendingPathComponent("Cache", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: fixture) }
        let cache = AnalysisCacheStore(rootDirectory: cacheRoot, sourceRoot: fixture)
        let state = try GraphScanner().scan(path: fixture.path, previousState: nil).state
        try cache.saveFrontendState(state)

        let report = try cache.performMaintenance(force: true, maximumBytes: 1, targetBytes: 0)

        XCTAssertEqual(report.removedArtifacts, 1)
        XCTAssertNil(cache.loadFrontendState())
    }

    func testMaintenancePreservesBusySharedDatabase() throws {
        #if canImport(Darwin)
        let fixture = try makeFixture()
        let cacheRoot = fixture.appendingPathComponent("Cache", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: fixture) }
        let cache = AnalysisCacheStore(rootDirectory: cacheRoot, sourceRoot: fixture)
        let database = cache.sharedIndexStoreDatabaseURL(identityData: Data("busy".utf8))
        try FileManager.default.createDirectory(at: database, withIntermediateDirectories: true)
        try Data(repeating: 1, count: 64_000).write(to: database.appendingPathComponent("payload"))
        let idleDatabase = cache.sharedIndexStoreDatabaseURL(identityData: Data("idle".utf8))
        try FileManager.default.createDirectory(at: idleDatabase, withIntermediateDirectories: true)
        try Data(repeating: 2, count: 64_000).write(to: idleDatabase.appendingPathComponent("payload"))
        let lockURL = database.appendingPathExtension("lock")
        let descriptor = open(lockURL.path, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)
        XCTAssertGreaterThanOrEqual(descriptor, 0)
        XCTAssertEqual(flock(descriptor, LOCK_EX | LOCK_NB), 0)
        defer {
            _ = flock(descriptor, LOCK_UN)
            close(descriptor)
        }

        let report = try cache.performMaintenance(force: true, maximumBytes: 16_000, targetBytes: 0)

        XCTAssertEqual(report.skippedBusyDatabases, 1)
        XCTAssertEqual(report.removedDatabases, 1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: database.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: idleDatabase.path))
        #endif
    }

    func testLegacyCacheWaitsForGraceAndThenIsRemoved() throws {
        let fixture = try makeFixture()
        let cacheRoot = fixture.appendingPathComponent("Cache", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: fixture) }
        let cache = AnalysisCacheStore(rootDirectory: cacheRoot, sourceRoot: fixture)
        try cache.saveIndexedGraph(SemanticGraph(nodes: [], edges: []), key: "success")
        let legacy = cacheRoot.appendingPathComponent("v1", isDirectory: true)
        try FileManager.default.createDirectory(at: legacy, withIntermediateDirectories: true)
        let legacyFile = legacy.appendingPathComponent("legacy.json")
        try Data("legacy".utf8).write(to: legacyFile)

        let recent = try cache.performMaintenance(force: true)
        XCTAssertFalse(recent.removedLegacy)
        XCTAssertTrue(FileManager.default.fileExists(atPath: legacy.path))

        let old = Date(timeIntervalSinceNow: -(AnalysisCacheStore.legacyGraceInterval + 60))
        let firstSuccess = cache.versionDirectoryURL.appendingPathComponent(".first-success")
        try FileManager.default.setAttributes([.modificationDate: old], ofItemAtPath: firstSuccess.path)
        let activeLegacy = try cache.performMaintenance(force: true)
        XCTAssertFalse(activeLegacy.removedLegacy)
        XCTAssertTrue(FileManager.default.fileExists(atPath: legacy.path))
        #if canImport(Darwin)
        var legacyTimes = [
            timeval(tv_sec: Int(old.timeIntervalSince1970), tv_usec: 0),
            timeval(tv_sec: Int(old.timeIntervalSince1970), tv_usec: 0),
        ]
        XCTAssertEqual(utimes(legacyFile.path, &legacyTimes), 0)
        #else
        try FileManager.default.setAttributes([.modificationDate: old], ofItemAtPath: legacyFile.path)
        #endif
        try FileManager.default.setAttributes([.modificationDate: old], ofItemAtPath: legacy.path)

        let expired = try cache.performMaintenance(force: true)
        XCTAssertTrue(expired.removedLegacy)
        XCTAssertFalse(FileManager.default.fileExists(atPath: legacy.path))
    }

    func testAddRenameAndDeleteRemainEquivalentToFullRebuild() throws {
        let fixture = try makeFixture()
        defer { try? FileManager.default.removeItem(at: fixture) }
        let scanner = GraphScanner()
        var state = try scanner.scan(path: fixture.path, previousState: nil).state

        try write("struct Helper { var count = 0 }", to: fixture.appendingPathComponent("Helper.swift"))
        let added = try scanner.scan(path: fixture.path, previousState: state)
        XCTAssertEqual(added.statistics.parsedFiles, ["Helper.swift"])
        XCTAssertEqual(try added.graph.jsonData(), try scanner.scan(path: fixture.path).jsonData())
        state = added.state

        try FileManager.default.moveItem(
            at: fixture.appendingPathComponent("Model.swift"),
            to: fixture.appendingPathComponent("Renamed.swift")
        )
        let renamed = try scanner.scan(path: fixture.path, previousState: state)
        XCTAssertEqual(renamed.statistics.parsedFiles, ["Renamed.swift", "Screen.swift"])
        XCTAssertEqual(try renamed.graph.jsonData(), try scanner.scan(path: fixture.path).jsonData())
        state = renamed.state

        try FileManager.default.removeItem(at: fixture.appendingPathComponent("Renamed.swift"))
        let deleted = try scanner.scan(path: fixture.path, previousState: state)
        XCTAssertEqual(deleted.statistics.parsedFiles, ["Screen.swift"])
        XCTAssertEqual(try deleted.graph.jsonData(), try scanner.scan(path: fixture.path).jsonData())
    }

    private func makeFixture() throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("swiftui-audit-incremental-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try write(
            """
            struct Model {
                var value = 0
            }
            """,
            to: root.appendingPathComponent("Model.swift")
        )
        try write(
            """
            import SwiftUI
            struct Screen: View {
                @State private var model = Model()
                var body: some View { Text("value") }
            }
            """,
            to: root.appendingPathComponent("Screen.swift")
        )
        return root
    }

    private func write(_ value: String, to url: URL) throws {
        try Data(value.utf8).write(to: url, options: .atomic)
    }
}
