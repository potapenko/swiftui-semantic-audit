import AnalysisCache
import AuditCore
import AuditRules
import ContextSlicer
import Foundation
import SemanticDiff
import SnapshotStore
import SymbolResolution
import SwiftSyntaxFrontend
import XCTest

final class SymbolResolutionTests: XCTestCase {
    func testCollisionSafeFileLocalIdentitiesRemapToDistinctCompilerUSRs() throws {
        let fixture = try makeIndexedCollisionFixture()
        defer { try? FileManager.default.removeItem(at: fixture.container) }
        let syntax = try GraphScanner().scan(path: fixture.source.path)
        let localTypes = syntax.nodes.filter { $0.qualifiedName == "IndexedCollision.Local" }
        XCTAssertEqual(localTypes.count, 2)
        XCTAssertEqual(Set(localTypes.map(\.id)).count, 2)

        let indexed = try directEnrichment(syntax, fixture: fixture, databaseName: "collision-db").graph
        let remapped = indexed.nodes.filter {
            $0.name == "Local" && $0.evidence.contains { $0.kind == "indexed-occurrence" }
        }
        XCTAssertEqual(indexed.resolution, "indexed")
        XCTAssertEqual(remapped.count, 2)
        XCTAssertEqual(Set(remapped.map(\.id)).count, 2)
    }

    func testConfiguredRolesFeaturesAndTypedEdgesSurviveIndexedEnrichment() throws {
        let fixture = try makeIndexedBoundaryFixture()
        defer { try? FileManager.default.removeItem(at: fixture.container) }
        let syntax = try GraphScanner().scan(path: fixture.source.path)
        let configuration = try AnalysisConfiguration(
            typeRoles: ["IndexedBoundary.IndexedPagerModel": .applicationModel],
            typeFeatures: ["IndexedBoundary.IndexedPagerModel": "paging"]
        )
        let configured = configuration.applying(to: syntax)
        let indexed = try directEnrichment(configured, fixture: fixture, databaseName: "configured-db").graph

        let model = try XCTUnwrap(indexed.nodes.first { $0.name == "IndexedPagerModel" })
        XCTAssertTrue(model.roles.contains("application-model"))
        XCTAssertEqual(model.feature, "paging")
        XCTAssertEqual(indexed.configurationDigest, configuration.digest)
        XCTAssertTrue(indexed.edges.contains { edge in
            edge.kind == .typedAs && indexed.nodes.contains { $0.id == edge.to && $0.id == model.id }
        })
    }

    func testBoundaryTopologyAndFindingsSurviveExplicitIndexedEnrichment() throws {
        let fixture = try makeIndexedBoundaryFixture()
        defer { try? FileManager.default.removeItem(at: fixture.container) }
        let syntax = try GraphScanner().scan(path: fixture.source.path)
        let indexed = try directEnrichment(syntax, fixture: fixture, databaseName: "boundary-db")
        let repeated = try directEnrichment(syntax, fixture: fixture, databaseName: "boundary-db-repeat")
        let binding = try XCTUnwrap(indexed.graph.nodes.first {
            $0.kind == .binding && $0.evidence.contains { $0.kind == "binding-construction" }
        })
        let setter = try XCTUnwrap(indexed.graph.edges.first {
            $0.kind == .sets && $0.from == binding.id && $0.evidence.contains { $0.kind == "binding-setter" }
        })
        let report = AuditEngine().audit(graph: indexed.graph)

        XCTAssertEqual(indexed.graph.resolution, "indexed")
        XCTAssertEqual(try indexed.graph.jsonData(), try repeated.graph.jsonData())
        XCTAssertEqual(binding.id, syntax.nodes.first { $0.evidence.contains { $0.kind == "binding-construction" } }?.id)
        XCTAssertTrue(indexed.graph.nodes.contains { $0.id == setter.to && $0.kind == .closure })
        XCTAssertEqual(Set(report.findings.map(\.rule)), [.commandShapedBinding, .broadObservableInput])
        XCTAssertEqual(report.resolution, "indexed")
        XCTAssertEqual(report.toolVersion, ToolMetadata.version)
    }

    func testActualIndexProvidesStableCrossFileUSRIdentityAndRelations() throws {
        let fixture = try makeIndexedFixture()
        defer { try? FileManager.default.removeItem(at: fixture.container) }
        let syntax = try GraphScanner().scan(path: fixture.source.path)
        let first = try directEnrichment(syntax, fixture: fixture, databaseName: "db-a")
        let second = try directEnrichment(syntax, fixture: fixture, databaseName: "db-b")

        XCTAssertEqual(first.graph.resolution, "indexed")
        XCTAssertGreaterThan(first.mappedSymbols, 0)
        XCTAssertGreaterThan(first.indexedFacts, 0)
        XCTAssertEqual(try first.graph.jsonData(), try second.graph.jsonData())
        XCTAssertEqual(Set(first.graph.nodes.map(\.id)).count, first.graph.nodes.count)
        XCTAssertEqual(Set(first.graph.edges.map(\.id)).count, first.graph.edges.count)
        let nodeIDs = Set(first.graph.nodes.map(\.id))
        XCTAssertTrue(first.graph.edges.allSatisfy { nodeIDs.contains($0.from) && nodeIDs.contains($0.to) })
        XCTAssertTrue(first.graph.nodes.flatMap(\.evidence).allSatisfy { !$0.file.hasPrefix("/") })
        XCTAssertTrue(first.graph.edges.flatMap(\.evidence).allSatisfy { !$0.file.hasPrefix("/") })

        let settingsVolume = try XCTUnwrap(first.graph.nodes.first {
            $0.qualifiedName.hasSuffix(".Settings.volume") && $0.evidence.contains { $0.file == "Settings.swift" }
        })
        let otherVolume = try XCTUnwrap(first.graph.nodes.first {
            $0.qualifiedName.hasSuffix(".OtherSettings.volume") && $0.evidence.contains { $0.file == "Settings.swift" }
        })
        let commit = try XCTUnwrap(first.graph.nodes.first { $0.qualifiedName.hasSuffix("VolumeWriter.commit") })
        let handle = try XCTUnwrap(first.graph.nodes.first { $0.qualifiedName.hasSuffix("VolumeCallback.handle") })
        let currentVolume = try XCTUnwrap(first.graph.nodes.first { $0.qualifiedName.hasSuffix("VolumeWriter.currentVolume") })
        let unrelated = try XCTUnwrap(first.graph.nodes.first { $0.qualifiedName.hasSuffix("VolumeWriter.unrelatedVolume") })
        XCTAssertNotEqual(settingsVolume.id, otherVolume.id)
        XCTAssertEqual(first.graph.nodes.filter { $0.kind == .property && $0.name == "volume" }.count, 2)
        XCTAssertFalse(first.graph.nodes.contains { $0.qualifiedName.hasSuffix("VolumeWriter.settings.volume") })
        XCTAssertFalse(first.graph.nodes.contains { $0.qualifiedName.hasSuffix("VolumeWriter.other.volume") })
        XCTAssertFalse(first.graph.nodes.contains { $0.qualifiedName.hasSuffix("VolumeCallback.writer.commit") })
        XCTAssertEqual(
            Set(first.graph.edges.map { "\($0.kind.rawValue)|\($0.from)|\($0.to)" }).count,
            first.graph.edges.count
        )
        XCTAssertTrue(first.graph.edges.contains { $0.kind == .calls && $0.from == handle.id && $0.to == commit.id })
        XCTAssertTrue(first.graph.edges.contains { $0.kind == .writes && $0.from == commit.id && $0.to == settingsVolume.id })
        XCTAssertTrue(first.graph.edges.contains { $0.kind == .reads && $0.from == currentVolume.id && $0.to == settingsVolume.id })
        XCTAssertTrue(first.graph.edges.contains { $0.kind == .reads && $0.from == unrelated.id && $0.to == otherVolume.id })
        XCTAssertFalse(first.graph.edges.contains { $0.kind == .reads && $0.from == unrelated.id && $0.to == settingsVolume.id })

        let report = AuditEngine().audit(graph: first.graph)
        XCTAssertEqual(report.resolution, "indexed")
        let loaded = try SemanticInputLoader().loadLive(
            sourceURL: fixture.source,
            indexSelection: .explicit(fixture.store),
            helperExecutable: projectRoot.appendingPathComponent(".build/debug/swiftui-audit")
        )
        XCTAssertEqual(loaded.snapshot.graph.resolution, "indexed")
        XCTAssertEqual(loaded.snapshot.report.resolution, "indexed")
        let doctor = EnvironmentDoctor(timeout: 30).inspect(
            path: fixture.source,
            helperExecutable: projectRoot.appendingPathComponent(".build/debug/swiftui-audit")
        )
        XCTAssertEqual(doctor.indexStore.status, .ok)
        XCTAssertTrue(doctor.indexStore.detail.contains("project coverage ready"))
        let snapshotDirectory = fixture.container.appendingPathComponent("snapshot")
        let manifest = SnapshotManifest(swiftVersion: "test", repositoryRevision: "indexed", generatedFrom: ".")
        try SnapshotWriter().write(
            graph: first.graph, report: report, manifest: manifest,
            sourceURL: fixture.source, to: snapshotDirectory
        )
        let snapshot = try SnapshotReader().read(from: snapshotDirectory)
        XCTAssertEqual(snapshot.graph, first.graph)
        let slice = try ContextSlicer().slice(graph: snapshot.graph, report: snapshot.report, symbol: commit.id)
        XCTAssertTrue(slice.nodes.contains { $0.id == commit.id })
        XCTAssertTrue(slice.edges.allSatisfy { edge in
            slice.nodes.contains { $0.id == edge.from } && slice.nodes.contains { $0.id == edge.to }
        })
    }

    func testLeadingLineShiftRetainsCompilerIDsAndSyntaxOnlyIsUntouched() throws {
        let original = try makeIndexedFixture()
        defer { try? FileManager.default.removeItem(at: original.container) }
        let shifted = try makeIndexedFixture(prefix: "\n\n\n")
        defer { try? FileManager.default.removeItem(at: shifted.container) }
        let originalSyntax = try GraphScanner().scan(path: original.source.path)
        let shiftedSyntax = try GraphScanner().scan(path: shifted.source.path)
        let originalIndexed = try directEnrichment(originalSyntax, fixture: original, databaseName: "db")
        let shiftedIndexed = try directEnrichment(shiftedSyntax, fixture: shifted, databaseName: "db")

        for suffix in [".Settings.volume", ".VolumeWriter.commit", ".VolumeCallback.handle"] {
            let lhs = originalIndexed.graph.nodes.first { $0.qualifiedName.hasSuffix(suffix) }?.id
            let rhs = shiftedIndexed.graph.nodes.first { $0.qualifiedName.hasSuffix(suffix) }?.id
            XCTAssertNotNil(lhs)
            XCTAssertEqual(lhs, rhs)
        }
        XCTAssertEqual(originalSyntax.resolution, "syntax-only")
        XCTAssertEqual(try originalSyntax.jsonData(), try GraphScanner().scan(path: original.source.path).jsonData())
    }

    func testBoundedHelperSelectionFallbackAndCleanupPolicies() throws {
        let fixture = try makeIndexedFixture()
        defer { try? FileManager.default.removeItem(at: fixture.container) }
        let syntax = try GraphScanner().scan(path: fixture.source.path)
        let executable = projectRoot.appendingPathComponent(".build/debug/swiftui-audit")
        XCTAssertTrue(FileManager.default.isExecutableFile(atPath: executable.path))
        let coordinator = IndexEnrichmentCoordinator(helperExecutable: executable, timeout: 30)
        let explicit = try coordinator.enrich(graph: syntax, sourceRoot: fixture.source, selection: .explicit(fixture.store))
        let repeated = try coordinator.enrich(graph: syntax, sourceRoot: fixture.source, selection: .explicit(fixture.store))
        XCTAssertEqual(explicit.resolution, "indexed")
        XCTAssertEqual(try explicit.jsonData(), try repeated.jsonData())
        XCTAssertEqual(try coordinator.enrich(graph: syntax, sourceRoot: fixture.source, selection: .syntaxOnly), syntax)
        XCTAssertEqual(
            try coordinator.enrich(graph: syntax, sourceRoot: fixture.source, selection: .automatic).resolution,
            "indexed"
        )
        XCTAssertEqual(
            try coordinator.enrich(
                graph: syntax,
                sourceRoot: URL(fileURLWithPath: fixture.source.path),
                selection: .automatic
            ).resolution,
            "indexed"
        )
        XCTAssertEqual(
            try coordinator.enrich(graph: syntax, sourceRoot: fixture.container.appendingPathComponent("NoIndex"), selection: .automatic),
            syntax
        )

        let duplicate = fixture.source.appendingPathComponent(".build/release/index/store", isDirectory: true)
        try FileManager.default.createDirectory(at: duplicate.deletingLastPathComponent(), withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: fixture.store, to: duplicate)
        XCTAssertEqual(try coordinator.enrich(graph: syntax, sourceRoot: fixture.source, selection: .automatic), syntax)
        XCTAssertThrowsError(try coordinator.enrich(
            graph: syntax,
            sourceRoot: fixture.source,
            selection: .explicit(fixture.container.appendingPathComponent("missing-store"))
        )) { XCTAssertTrue($0 is IndexResolutionError) }
        XCTAssertThrowsError(try IndexEnrichmentCoordinator(
            helperExecutable: fixture.container.appendingPathComponent("missing-helper")
        ).enrich(graph: syntax, sourceRoot: fixture.source, selection: .explicit(fixture.store))) {
            guard case IndexResolutionError.invalidHelper = $0 else {
                return XCTFail("unexpected error: \($0)")
            }
        }

        let helperRoot = fixture.container.appendingPathComponent("helper-temp", isDirectory: true)
        try FileManager.default.createDirectory(at: helperRoot, withIntermediateDirectories: true)
        let timed = IndexEnrichmentCoordinator(
            helperExecutable: executable,
            runner: TimeoutAfterToolchainRunner(),
            timeout: 0.01,
            temporaryRoot: helperRoot
        )
        XCTAssertThrowsError(try timed.enrich(
            graph: syntax, sourceRoot: fixture.source, selection: .explicit(fixture.store)
        )) { guard case BoundedProcessError.timeout = $0 else { return XCTFail("unexpected error: \($0)") } }
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: helperRoot.path), [])

        let crashed = IndexEnrichmentCoordinator(
            helperExecutable: executable,
            runner: CrashAfterToolchainRunner(),
            timeout: 1,
            temporaryRoot: helperRoot
        )
        XCTAssertThrowsError(try crashed.enrich(
            graph: syntax, sourceRoot: fixture.source, selection: .explicit(fixture.store)
        )) { guard case IndexResolutionError.helperFailed(9, _) = $0 else { return XCTFail("unexpected error: \($0)") } }
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: helperRoot.path), [])
    }

    func testIndexedGraphCacheAvoidsRepeatedHelperAndMatchesUncachedResult() throws {
        let fixture = try makeIndexedFixture()
        defer { try? FileManager.default.removeItem(at: fixture.container) }
        let syntax = try GraphScanner().scan(path: fixture.source.path)
        let executable = projectRoot.appendingPathComponent(".build/debug/swiftui-audit")
        let factCache = AnalysisCacheStore(
            rootDirectory: fixture.container.appendingPathComponent("fact-cache", isDirectory: true),
            sourceRoot: fixture.source
        )
        let firstFacts = try IndexStoreDBResolver().enrich(IndexEnrichmentRequest(
            sourceRoot: fixture.source.path,
            indexStorePath: fixture.store.path,
            databasePath: fixture.container.appendingPathComponent("fact-db-a").path,
            indexStoreLibraryPath: indexStoreLibrary.path,
            cacheDirectory: factCache.projectDirectoryURL.path,
            graph: syntax
        ))
        let warmFacts = try IndexStoreDBResolver().enrich(IndexEnrichmentRequest(
            sourceRoot: fixture.source.path,
            indexStorePath: fixture.store.path,
            databasePath: fixture.container.appendingPathComponent("fact-db-b").path,
            indexStoreLibraryPath: indexStoreLibrary.path,
            cacheDirectory: factCache.projectDirectoryURL.path,
            graph: syntax
        ))
        XCTAssertGreaterThan(firstFacts.analyzedFiles, 0)
        XCTAssertEqual(firstFacts.cachedFiles, 0)
        XCTAssertEqual(warmFacts.cachedFiles, firstFacts.analyzedFiles)
        XCTAssertEqual(warmFacts.analyzedFiles, 0)
        XCTAssertEqual(try firstFacts.graph.jsonData(), try warmFacts.graph.jsonData())

        let cache = AnalysisCacheStore(
            rootDirectory: fixture.container.appendingPathComponent("cache", isDirectory: true),
            sourceRoot: fixture.source
        )
        let cold = try IndexEnrichmentCoordinator(helperExecutable: executable, timeout: 30).enrich(
            graph: syntax,
            sourceRoot: fixture.source,
            selection: .explicit(fixture.store),
            cache: cache
        )
        let warm = try IndexEnrichmentCoordinator(
            helperExecutable: executable,
            runner: CrashAfterToolchainRunner(),
            timeout: 30
        ).enrich(
            graph: syntax,
            sourceRoot: fixture.source,
            selection: .explicit(fixture.store),
            cache: cache
        )
        let databaseRoot = cache.projectDirectoryURL.appendingPathComponent("indexstoredb", isDirectory: true)
        let firstDatabaseEntries = try FileManager.default.contentsOfDirectory(
            at: databaseRoot, includingPropertiesForKeys: [.isDirectoryKey]
        ).filter { $0.pathExtension != "lock" }
        XCTAssertEqual(firstDatabaseEntries.count, 1)
        let changedGraph = SemanticGraph(
            resolution: syntax.resolution,
            configurationDigest: "parallel-index-cache-test",
            nodes: syntax.nodes,
            edges: syntax.edges
        )
        let changed = try IndexEnrichmentCoordinator(helperExecutable: executable, timeout: 30).enrich(
            graph: changedGraph,
            sourceRoot: fixture.source,
            selection: .explicit(fixture.store),
            cache: cache
        )
        XCTAssertEqual(changed.resolution, "indexed")
        XCTAssertEqual(changed.configurationDigest, "parallel-index-cache-test")
        let reusedDatabaseEntries = try FileManager.default.contentsOfDirectory(
            at: databaseRoot, includingPropertiesForKeys: [.isDirectoryKey]
        ).filter { $0.pathExtension != "lock" }
        XCTAssertEqual(reusedDatabaseEntries.map(\.lastPathComponent), firstDatabaseEntries.map(\.lastPathComponent))
        let uncached = try IndexEnrichmentCoordinator(helperExecutable: executable, timeout: 30).enrich(
            graph: syntax,
            sourceRoot: fixture.source,
            selection: .explicit(fixture.store)
        )

        XCTAssertEqual(warm.resolution, "indexed")
        XCTAssertEqual(try cold.jsonData(), try warm.jsonData())
        XCTAssertEqual(try warm.jsonData(), try uncached.jsonData())
    }

    func testInvalidNoCoverageAndPackageLockTruth() throws {
        let fixture = try makeIndexedFixture()
        defer { try? FileManager.default.removeItem(at: fixture.container) }
        let syntax = try GraphScanner().scan(path: fixture.source.path)
        let empty = fixture.container.appendingPathComponent("empty-store", isDirectory: true)
        try FileManager.default.createDirectory(at: empty, withIntermediateDirectories: true)
        XCTAssertThrowsError(try IndexStoreLocator().validatedExplicitStore(empty))

        let unrelatedRoot = fixture.container.appendingPathComponent("Unrelated", isDirectory: true)
        try FileManager.default.createDirectory(at: unrelatedRoot, withIntermediateDirectories: true)
        try "struct Unrelated {}\n".write(
            to: unrelatedRoot.appendingPathComponent("Unrelated.swift"), atomically: true, encoding: .utf8
        )
        let unrelatedStore = fixture.container.appendingPathComponent("unrelated-store", isDirectory: true)
        try buildIndex(source: unrelatedRoot, store: unrelatedStore, output: fixture.container.appendingPathComponent("unrelated-out"))
        let executable = projectRoot.appendingPathComponent(".build/debug/swiftui-audit")
        XCTAssertThrowsError(try IndexEnrichmentCoordinator(helperExecutable: executable).enrich(
            graph: syntax, sourceRoot: fixture.source, selection: .explicit(unrelatedStore)
        )) { XCTAssertTrue($0.localizedDescription.contains("no coverage")) }

        let noCoverageSource = fixture.container.appendingPathComponent("NoCoverageProject", isDirectory: true)
        try FileManager.default.copyItem(at: fixtureRoot, to: noCoverageSource)
        let autoUnrelatedStore = noCoverageSource.appendingPathComponent(".build/debug/index/store", isDirectory: true)
        try buildIndex(
            source: unrelatedRoot,
            store: autoUnrelatedStore,
            output: fixture.container.appendingPathComponent("auto-unrelated-out")
        )
        let noCoverageSyntax = try GraphScanner().scan(path: noCoverageSource.path)
        XCTAssertEqual(
            try IndexEnrichmentCoordinator(helperExecutable: executable).enrich(
                graph: noCoverageSyntax, sourceRoot: noCoverageSource, selection: .automatic
            ),
            noCoverageSyntax
        )

        let resolved = try JSONSerialization.jsonObject(
            with: Data(contentsOf: projectRoot.appendingPathComponent("Package.resolved"))
        ) as! [String: Any]
        let pins = resolved["pins"] as! [[String: Any]]
        let indexPin = pins.first { $0["identity"] as? String == "indexstore-db" }
        let lmdbPin = pins.first { $0["identity"] as? String == "swift-lmdb" }
        XCTAssertEqual((indexPin?["state"] as? [String: Any])?["revision"] as? String, "003ac41513ba291f10ff1a0147ae68588914668d")
        XCTAssertEqual((lmdbPin?["state"] as? [String: Any])?["revision"] as? String, "1ad9a2d80b6fcde498c2242f509bd1be7d667ff8")
    }

    func testSameLineDifferentLeafUSRsRemainConservativelyUnmerged() throws {
        let fixture = try makeIndexedFixture(includeSameLineAmbiguity: true)
        defer { try? FileManager.default.removeItem(at: fixture.container) }
        let syntax = try GraphScanner().scan(path: fixture.source.path)
        let indexed = try directEnrichment(syntax, fixture: fixture, databaseName: "db")
        let combined = try XCTUnwrap(indexed.graph.nodes.first {
            $0.qualifiedName.hasSuffix("VolumeWriter.combinedVolume")
        })
        let settingsVolume = try XCTUnwrap(indexed.graph.nodes.first {
            $0.qualifiedName.hasSuffix(".Settings.volume") && $0.kind == .property
        })
        let otherVolume = try XCTUnwrap(indexed.graph.nodes.first {
            $0.qualifiedName.hasSuffix(".OtherSettings.volume") && $0.kind == .property
        })
        XCTAssertTrue(indexed.graph.edges.contains {
            $0.kind == .reads && $0.from == combined.id && $0.to == settingsVolume.id
        })
        XCTAssertTrue(indexed.graph.edges.contains {
            $0.kind == .reads && $0.from == combined.id && $0.to == otherVolume.id
        })
        let volumeProperties = indexed.graph.nodes.filter { $0.kind == .property && $0.name == "volume" }
        XCTAssertEqual(Set(volumeProperties.map(\.id)), Set([settingsVolume.id, otherVolume.id]))
        XCTAssertFalse(indexed.graph.edges.contains { edge in
            edge.kind == .reads && edge.from == combined.id &&
                edge.to != settingsVolume.id && edge.to != otherVolume.id &&
                indexed.graph.nodes.contains { node in node.id == edge.to && node.name == "volume" }
        })
    }

    func testResolutionPolicyAndPathInvocationUseActualExecutable() throws {
        let fixture = try makeIndexedFixture()
        defer { try? FileManager.default.removeItem(at: fixture.container) }
        let syntax = try GraphScanner().scan(path: fixture.source.path)
        let indexed = try directEnrichment(syntax, fixture: fixture, databaseName: "policy-db").graph
        let syntaxSnapshot = fixture.container.appendingPathComponent("syntax-snapshot", isDirectory: true)
        let indexedSnapshot = fixture.container.appendingPathComponent("indexed-snapshot", isDirectory: true)
        try writeSnapshot(graph: syntax, source: fixture.source, output: syntaxSnapshot)
        try writeSnapshot(graph: indexed, source: fixture.source, output: indexedSnapshot)

        let executable = projectRoot.appendingPathComponent(".build/debug/swiftui-audit")
        let runner = BoundedProcessRunner()
        let syntaxAuto = try runner.run(
            executable.path,
            arguments: ["check", "--baseline", syntaxSnapshot.path, fixture.source.path, "--format", "json"],
            timeout: 60
        )
        XCTAssertEqual(syntaxAuto.status, 0, syntaxAuto.errorString)
        XCTAssertTrue(try JSONDecoder().decode(CheckReport.self, from: syntaxAuto.standardOutput).passed)

        let syntaxExplicit = try runner.run(
            executable.path,
            arguments: [
                "check", "--baseline", syntaxSnapshot.path, fixture.source.path,
                "--index-store", fixture.store.path, "--format", "json",
            ],
            timeout: 60
        )
        XCTAssertEqual(syntaxExplicit.status, 1)
        XCTAssertTrue(syntaxExplicit.standardOutput.isEmpty)
        XCTAssertTrue(syntaxExplicit.errorString.contains("resolution mismatch"))

        for arguments in [
            ["check", "--baseline", indexedSnapshot.path, fixture.source.path, "--index-store", fixture.store.path, "--format", "json"],
            ["check", "--baseline", indexedSnapshot.path, fixture.source.path, "--format", "json"],
        ] {
            let result = try runner.run(executable.path, arguments: arguments, timeout: 60)
            XCTAssertEqual(result.status, 0, result.errorString)
        }
        let indexedSyntax = try runner.run(
            executable.path,
            arguments: ["check", "--baseline", indexedSnapshot.path, fixture.source.path, "--syntax-only", "--format", "json"],
            timeout: 60
        )
        XCTAssertEqual(indexedSyntax.status, 1)
        XCTAssertTrue(indexedSyntax.standardOutput.isEmpty)
        XCTAssertTrue(indexedSyntax.errorString.contains("resolution mismatch"))
        let noIndexSource = fixture.container.appendingPathComponent("No Index Source", isDirectory: true)
        try FileManager.default.copyItem(at: fixtureRoot, to: noIndexSource)
        let indexedUnavailable = try runner.run(
            executable.path,
            arguments: ["check", "--baseline", indexedSnapshot.path, noIndexSource.path, "--format", "json"],
            timeout: 60
        )
        XCTAssertEqual(indexedUnavailable.status, 1)
        XCTAssertTrue(indexedUnavailable.standardOutput.isEmpty)
        XCTAssertTrue(indexedUnavailable.errorString.contains("resolution mismatch"))

        let mixedDiff = try runner.run(
            executable.path,
            arguments: ["diff", syntaxSnapshot.path, indexedSnapshot.path, "--format", "json"],
            timeout: 30
        )
        XCTAssertEqual(mixedDiff.status, 1)
        XCTAssertTrue(mixedDiff.standardOutput.isEmpty)
        XCTAssertTrue(mixedDiff.errorString.contains("resolution mismatch"))

        let revisionRepository = fixture.container.appendingPathComponent("Revision", isDirectory: true)
        try FileManager.default.createDirectory(at: revisionRepository, withIntermediateDirectories: true)
        try "struct Baseline {}\n".write(
            to: revisionRepository.appendingPathComponent("Baseline.swift"), atomically: true, encoding: .utf8
        )
        for arguments in [
            ["init", "-q"],
            ["config", "user.email", "tests@example.invalid"],
            ["config", "user.name", "Tests"],
            ["add", "Baseline.swift"],
            ["commit", "-qm", "baseline"],
        ] {
            _ = try runner.runChecked("git", arguments: arguments, currentDirectory: revisionRepository, timeout: 10)
        }
        let revisionExplicit = try runner.run(
            executable.path,
            arguments: [
                "check", "--baseline", "HEAD", "--repository", revisionRepository.path,
                fixture.source.path, "--index-store", fixture.store.path, "--format", "json",
            ],
            timeout: 60
        )
        XCTAssertEqual(revisionExplicit.status, 1)
        XCTAssertTrue(revisionExplicit.standardOutput.isEmpty)
        XCTAssertTrue(revisionExplicit.errorString.contains("resolution mismatch"))
        let revisionAuto = try runner.run(
            executable.path,
            arguments: [
                "check", "--baseline", "HEAD", "--repository", revisionRepository.path,
                fixture.source.path, "--format", "json",
            ],
            timeout: 60
        )
        XCTAssertEqual(revisionAuto.status, 0, revisionAuto.errorString)
        XCTAssertTrue(try JSONDecoder().decode(CheckReport.self, from: revisionAuto.standardOutput).passed)

        let foreign = fixture.container.appendingPathComponent("Foreign Working Directory", isDirectory: true)
        try FileManager.default.createDirectory(at: foreign, withIntermediateDirectories: true)
        let path = executable.deletingLastPathComponent().path + ":" +
            (ProcessInfo.processInfo.environment["PATH"] ?? "/usr/bin:/bin")
        func pathInvocation(_ arguments: [String], timeout: TimeInterval = 60) throws -> BoundedProcessResult {
            try runner.run(
                "/usr/bin/env",
                arguments: ["PATH=\(path)", "swiftui-audit"] + arguments,
                currentDirectory: foreign,
                timeout: timeout
            )
        }
        for arguments in [
            ["scan", fixture.source.path, "--index-store", fixture.store.path, "--jobs", "2", "--format", "json"],
            ["scan", fixture.source.path, "--jobs", "1", "--format", "json"],
        ] {
            let result = try pathInvocation(arguments)
            XCTAssertEqual(result.status, 0, result.errorString)
            XCTAssertEqual(try JSONDecoder().decode(SemanticGraph.self, from: result.standardOutput).resolution, "indexed")
        }
        let doctor = try pathInvocation(["doctor", fixture.source.path, "--format", "json"])
        XCTAssertEqual(doctor.status, 0, doctor.errorString)
        XCTAssertEqual(try JSONDecoder().decode(DoctorReport.self, from: doctor.standardOutput).indexStore.status, .ok)
        let help = try pathInvocation(["--help"], timeout: 10)
        XCTAssertEqual(help.status, 0)
        XCTAssertFalse(help.outputString.contains("_index-enrich"))
        let invalidJobs = try pathInvocation(["scan", fixture.source.path, "--syntax-only", "--jobs", "0"])
        XCTAssertNotEqual(invalidJobs.status, 0)
        XCTAssertTrue(invalidJobs.errorString.contains("--jobs must be positive"))
    }

    private func makeIndexedFixture(prefix: String = "", includeSameLineAmbiguity: Bool = false) throws -> Fixture {
        let container = FileManager.default.temporaryDirectory
            .appendingPathComponent("swiftui-audit-index-tests-\(UUID().uuidString)", isDirectory: true)
        let source = container.appendingPathComponent("IndexedProject", isDirectory: true)
        try FileManager.default.createDirectory(at: container, withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: fixtureRoot, to: source)
        if includeSameLineAmbiguity {
            let writerURL = source.appendingPathComponent("Writer.swift")
            var writer = try String(contentsOf: writerURL, encoding: .utf8)
            XCTAssertTrue(writer.hasSuffix("}\n"))
            writer.removeLast(2)
            writer += """

                func combinedVolume() -> Int {
                    settings.volume + other.volume
                }
            }
            """
            try writer.write(to: writerURL, atomically: true, encoding: .utf8)
        }
        if !prefix.isEmpty {
            for file in try FileManager.default.contentsOfDirectory(at: source, includingPropertiesForKeys: nil)
                .filter({ $0.pathExtension == "swift" }) {
                let contents = try String(contentsOf: file, encoding: .utf8)
                try (prefix + contents).write(to: file, atomically: true, encoding: .utf8)
            }
        }
        let store = source.appendingPathComponent(".build/debug/index/store", isDirectory: true)
        try buildIndex(source: source, store: store, output: container.appendingPathComponent("output"))
        return Fixture(container: container, source: source, store: store)
    }

    private func makeIndexedBoundaryFixture() throws -> Fixture {
        let container = FileManager.default.temporaryDirectory
            .appendingPathComponent("swiftui-audit-boundary-index-tests-\(UUID().uuidString)", isDirectory: true)
        let source = container.appendingPathComponent("IndexedBoundary", isDirectory: true)
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        try """
        import Observation
        import SwiftUI

        @Observable
        final class IndexedPagerModel {
            var page = 0
            func selectPage(_ page: Int) { self.page = page }
        }

        struct IndexedCommandPager: View {
            @Bindable var model: IndexedPagerModel
            var body: some View {
                Picker("Page", selection: Binding(
                    get: { model.page },
                    set: { model.selectPage($0) }
                )) { Text("Zero").tag(0) }
            }
        }
        """.write(to: source.appendingPathComponent("Fixture.swift"), atomically: true, encoding: .utf8)
        let store = source.appendingPathComponent(".build/debug/index/store", isDirectory: true)
        try buildIndex(source: source, store: store, output: container.appendingPathComponent("output"))
        return Fixture(container: container, source: source, store: store)
    }

    private func makeIndexedCollisionFixture() throws -> Fixture {
        let container = FileManager.default.temporaryDirectory
            .appendingPathComponent("swiftui-audit-collision-index-tests-\(UUID().uuidString)", isDirectory: true)
        let source = container.appendingPathComponent("IndexedCollision", isDirectory: true)
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        try """
        private struct Local { var value: Int }
        func first() -> Int { Local(value: 1).value }
        """.write(to: source.appendingPathComponent("A.swift"), atomically: true, encoding: .utf8)
        try """
        private struct Local { var value: Int }
        func second() -> Int { Local(value: 2).value }
        """.write(to: source.appendingPathComponent("B.swift"), atomically: true, encoding: .utf8)
        let store = source.appendingPathComponent(".build/debug/index/store", isDirectory: true)
        try buildIndex(source: source, store: store, output: container.appendingPathComponent("output"))
        return Fixture(container: container, source: source, store: store)
    }

    private func buildIndex(source: URL, store: URL, output: URL) throws {
        try FileManager.default.createDirectory(at: store, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let files = try FileManager.default.contentsOfDirectory(at: source, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "swift" }.sorted { $0.path < $1.path }
        _ = try BoundedProcessRunner().runChecked(
            "/usr/bin/xcrun",
            arguments: ["swiftc", "-module-name", "IndexedProject", "-index-store-path", store.path, "-emit-module"]
                + files.map(\.path) + ["-o", output.appendingPathComponent("IndexedProject.swiftmodule").path],
            timeout: 60
        )
    }

    private func directEnrichment(_ graph: SemanticGraph, fixture: Fixture, databaseName: String) throws -> IndexEnrichmentResponse {
        try IndexStoreDBResolver().enrich(IndexEnrichmentRequest(
            sourceRoot: fixture.source.path,
            indexStorePath: fixture.store.path,
            databasePath: fixture.container.appendingPathComponent(databaseName).path,
            indexStoreLibraryPath: indexStoreLibrary.path,
            graph: graph
        ))
    }

    private func writeSnapshot(graph: SemanticGraph, source: URL, output: URL) throws {
        let report = AuditEngine().audit(graph: graph)
        try SnapshotWriter().write(
            graph: graph,
            report: report,
            manifest: SnapshotManifest(swiftVersion: "test", repositoryRevision: "test", generatedFrom: "."),
            sourceURL: source,
            to: output
        )
    }

    private var indexStoreLibrary: URL {
        let result = try! BoundedProcessRunner().runChecked(
            "/usr/bin/xcrun", arguments: ["--find", "swiftc"], timeout: 5
        )
        let swiftc = URL(fileURLWithPath: result.outputString.trimmingCharacters(in: .whitespacesAndNewlines))
            .standardizedFileURL.resolvingSymlinksInPath()
        return swiftc.deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("lib/libIndexStore.dylib")
    }

    private var projectRoot: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
    }

    private var fixtureRoot: URL {
        projectRoot.appendingPathComponent("Tests/Fixtures/IndexedProject", isDirectory: true)
    }
}

private struct Fixture {
    let container: URL
    let source: URL
    let store: URL
}

private struct TimeoutAfterToolchainRunner: ProcessRunning {
    func run(
        _ command: String,
        arguments: [String],
        currentDirectory: URL?,
        timeout: TimeInterval
    ) throws -> BoundedProcessResult {
        if command == "/usr/bin/xcrun" {
            return try BoundedProcessRunner().run(command, arguments: arguments, currentDirectory: currentDirectory, timeout: 5)
        }
        throw BoundedProcessError.timeout(([command] + arguments).joined(separator: " "), timeout)
    }
}

private struct CrashAfterToolchainRunner: ProcessRunning {
    func run(
        _ command: String,
        arguments: [String],
        currentDirectory: URL?,
        timeout: TimeInterval
    ) throws -> BoundedProcessResult {
        if command == "/usr/bin/xcrun" {
            return try BoundedProcessRunner().run(command, arguments: arguments, currentDirectory: currentDirectory, timeout: 5)
        }
        return BoundedProcessResult(status: 9, standardOutput: Data(), standardError: Data("crashed".utf8))
    }
}
