import AnalysisCache
import Foundation
import SwiftSyntaxFrontend
import XCTest

final class IncrementalGraphScannerTests: XCTestCase {
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
