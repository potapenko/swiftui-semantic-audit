import AuditCore
import Foundation
import ProjectWorkspace
import SymbolResolution

public enum ProjectBuildError: Error, LocalizedError {
    case failed(String)
    case indexStore(String)

    public var errorDescription: String? {
        switch self {
        case .failed(let detail): "project build failed: \(detail)"
        case .indexStore(let detail): "project Index Store unavailable: \(detail)"
        }
    }
}

public struct ProjectBuilder: Sendable {
    private let runner: any ProcessRunning

    public init(runner: any ProcessRunning = BoundedProcessRunner()) {
        self.runner = runner
    }

    public func build(
        projectRoot: URL,
        manifest: ProjectManifest,
        runtimeRoot: URL,
        timeout: TimeInterval
    ) throws -> URL {
        let result: BoundedProcessResult
        switch manifest.build.kind {
        case .swiftPM:
            result = try runner.run(
                "swift", arguments: ["build"], currentDirectory: projectRoot, timeout: timeout
            )
        case .xcode:
            guard let container = manifest.build.container,
                  let scheme = manifest.build.scheme,
                  let platform = manifest.build.platform else {
                throw ProjectBuildError.failed("incomplete Xcode adapter")
            }
            let derivedData = runtimeRoot.appendingPathComponent("DerivedData", isDirectory: true)
            let containerFlag = container.hasSuffix(".xcworkspace") ? "-workspace" : "-project"
            result = try runner.run(
                "xcodebuild",
                arguments: [
                    containerFlag, container,
                    "-scheme", scheme,
                    "-destination", "generic/platform=\(platform)",
                    "-derivedDataPath", derivedData.path,
                    "COMPILER_INDEX_STORE_ENABLE=YES",
                    "build",
                ],
                currentDirectory: projectRoot,
                timeout: timeout
            )
        }
        guard result.status == 0 else {
            let detail = result.errorString.trimmingCharacters(in: .whitespacesAndNewlines)
            throw ProjectBuildError.failed(detail.isEmpty ? "status \(result.status)" : detail)
        }
        let candidates: [URL]
        switch manifest.build.kind {
        case .swiftPM:
            candidates = IndexStoreLocator().automaticStores(sourceRoot: projectRoot)
        case .xcode:
            candidates = rawStores(under: runtimeRoot.appendingPathComponent("DerivedData", isDirectory: true))
        }
        guard candidates.count == 1, let store = candidates.first else {
            throw ProjectBuildError.indexStore("expected one validated store, found \(candidates.count)")
        }
        return try IndexStoreLocator().validatedExplicitStore(store)
    }

    private func rawStores(under root: URL) -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: root, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]
        ) else { return [] }
        var byPath: [String: URL] = [:]
        for case let url as URL in enumerator where IndexStoreLocator.hasRawStoreShape(url) {
            let canonical = url.standardizedFileURL.resolvingSymlinksInPath()
            byPath[canonical.path] = canonical
            enumerator.skipDescendants()
        }
        return byPath.values.sorted { $0.path < $1.path }
    }
}
