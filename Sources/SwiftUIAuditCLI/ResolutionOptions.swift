import ArgumentParser
import AuditCore
import Foundation
import SymbolResolution
import SwiftSyntaxFrontend
#if canImport(Darwin)
import Darwin
#endif

struct ResolutionOptions: ParsableArguments {
    @Option(name: .long, help: "Explicit compiler Index Store path.")
    var indexStore: String?

    @Flag(name: .long, help: "Disable all compiler-index enrichment.")
    var syntaxOnly = false

    func selection() throws -> IndexSelection {
        if syntaxOnly && indexStore != nil {
            throw ValidationError("--syntax-only and --index-store cannot be used together")
        }
        if syntaxOnly { return .syntaxOnly }
        if let indexStore {
            return .explicit(URL(fileURLWithPath: indexStore, isDirectory: true))
        }
        return .automatic
    }
}

func loadResolvedGraph(path: String, options: ResolutionOptions) throws -> SemanticGraph {
    let source = URL(fileURLWithPath: path).standardizedFileURL.resolvingSymlinksInPath()
    let graph = try GraphScanner().scan(path: source.path)
    return try IndexEnrichmentCoordinator(helperExecutable: currentExecutableURL()).enrich(
        graph: graph,
        sourceRoot: source,
        selection: options.selection()
    )
}

enum ExecutableResolutionError: Error, LocalizedError {
    case unavailable

    var errorDescription: String? {
        "unable to resolve the running swiftui-audit executable to a regular executable file"
    }
}

func currentExecutableURL() throws -> URL {
    var candidates: [URL] = []
    if let bundled = Bundle.main.executableURL { candidates.append(bundled) }
    if let process = processExecutableURL() { candidates.append(process) }
    let argument = CommandLine.arguments[0]
    if argument.contains("/") {
        candidates.append(URL(fileURLWithPath: argument))
    }
    for candidate in candidates {
        let canonical = candidate.standardizedFileURL.resolvingSymlinksInPath()
        guard let values = try? canonical.resourceValues(forKeys: [.isRegularFileKey]),
              values.isRegularFile == true,
              FileManager.default.isExecutableFile(atPath: canonical.path)
        else { continue }
        return canonical
    }
    throw ExecutableResolutionError.unavailable
}

private func processExecutableURL() -> URL? {
    #if canImport(Darwin)
    var size: UInt32 = 0
    _ = _NSGetExecutablePath(nil, &size)
    guard size > 0 else { return nil }
    var buffer = [CChar](repeating: 0, count: Int(size))
    let status = buffer.withUnsafeMutableBufferPointer { pointer in
        _NSGetExecutablePath(pointer.baseAddress, &size)
    }
    guard status == 0 else { return nil }
    let bytes = buffer.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }
    return URL(fileURLWithPath: String(decoding: bytes, as: UTF8.self))
    #else
    let proc = URL(fileURLWithPath: "/proc/self/exe")
    guard let destination = try? FileManager.default.destinationOfSymbolicLink(atPath: proc.path) else {
        return nil
    }
    return URL(fileURLWithPath: destination)
    #endif
}
