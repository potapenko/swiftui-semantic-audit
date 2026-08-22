import ArgumentParser
import Foundation
import ProjectWorkspace
import WatcherRuntime

struct Project: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Set up and operate continuous semantic project analysis.",
        subcommands: [ProjectSetup.self, ProjectWatch.self, ProjectStart.self, ProjectStatusCommand.self, ProjectStop.self, ProjectBaseline.self]
    )
}

enum ProjectOutputFormat: String, ExpressibleByArgument {
    case json
}

struct ProjectSetup: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "setup",
        abstract: "Preview or apply deterministic project watcher setup."
    )

    @Argument(help: "Project root.") var path: String = "."
    @Flag(name: .long, help: "Apply the previewed setup plan.") var apply = false
    @Flag(name: .long, help: "Start the project watcher after applying setup.") var start = false
    @Flag(name: .long, help: "Create the initial indexed baseline after applying setup.") var createBaseline = false
    @Option(name: .long, help: "Relative source root override.") var sourceRoot: String?
    @Option(name: .long, help: "Relative .xcodeproj or .xcworkspace override.") var container: String?
    @Option(name: .long, help: "Shared Xcode scheme override.") var scheme: String?
    @Option(name: .long, help: "Xcode destination platform, such as macOS or iOS Simulator.") var platform: String?
    @Option(name: .long, help: "Output format.") var format: ProjectOutputFormat?

    mutating func validate() throws {
        if (start || createBaseline) && !apply {
            throw ValidationError("--start and --create-baseline require --apply")
        }
    }

    mutating func run() throws {
        let root = URL(fileURLWithPath: path, isDirectory: true)
        let planner = ProjectSetupPlanner()
        let plan = try planner.plan(
            projectRoot: root,
            options: ProjectSetupOptions(
                sourceRoot: sourceRoot,
                container: container,
                scheme: scheme,
                platform: platform
            )
        )
        var response = plan
        if apply {
            response = try planner.apply(plan)
            if createBaseline {
                let watcher = WatcherCoordinator()
                _ = try watcher.runOnce(projectRoot: root, helperExecutable: currentExecutableURL())
                _ = try watcher.promoteBaseline(projectRoot: root)
            }
            if start {
                _ = try ProjectServiceController().start(
                    projectRoot: root.standardizedFileURL.resolvingSymlinksInPath(),
                    executable: currentExecutableURL()
                )
            }
        }
        FileHandle.standardOutput.write(try response.jsonData())
    }
}

struct ProjectWatch: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "watch",
        abstract: "Continuously refresh freshness-qualified semantic project state."
    )

    @Argument(help: "Project root.") var path: String = "."
    @Flag(name: .long, help: "Run one generation and exit.") var once = false
    @Option(name: .long, help: "Build and analysis timeout in seconds.") var timeout: Double = 300
    @Option(name: .long, help: "Output format.") var format: ProjectOutputFormat?

    mutating func validate() throws {
        guard timeout > 0 else { throw ValidationError("--timeout must be positive") }
    }

    mutating func run() throws {
        let root = URL(fileURLWithPath: path, isDirectory: true)
        let watcher = WatcherCoordinator(timeout: timeout)
        if once {
            let status = try watcher.runOnce(projectRoot: root, helperExecutable: currentExecutableURL())
            FileHandle.standardOutput.write(try status.jsonData())
        } else {
            try watcher.watch(projectRoot: root, helperExecutable: currentExecutableURL())
        }
    }
}

struct ProjectStart: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "start",
        abstract: "Start the managed watcher for one configured project."
    )

    @Argument(help: "Project root.") var path: String = "."
    @Option(name: .long, help: "Output format.") var format: ProjectOutputFormat?

    mutating func run() throws {
        let root = URL(fileURLWithPath: path, isDirectory: true).standardizedFileURL.resolvingSymlinksInPath()
        _ = try ProjectManifest.load(projectRoot: root)
        let result = try ProjectServiceController().start(
            projectRoot: root, executable: currentExecutableURL()
        )
        FileHandle.standardOutput.write(try result.jsonData())
    }
}

struct ProjectStatusCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "status",
        abstract: "Read or boundedly wait for project watcher freshness."
    )

    enum WaitCondition: String, ExpressibleByArgument { case indexed }

    @Argument(help: "Project root.") var path: String = "."
    @Option(name: .long, help: "Wait condition.") var wait: WaitCondition?
    @Option(name: .long, help: "Maximum wait in seconds.") var timeout: Double = 120
    @Option(name: .long, help: "Output format.") var format: ProjectOutputFormat?

    mutating func validate() throws {
        guard timeout > 0 else { throw ValidationError("--timeout must be positive") }
    }

    mutating func run() throws {
        let root = URL(fileURLWithPath: path, isDirectory: true)
        let watcher = WatcherCoordinator()
        let deadline = Date().addingTimeInterval(timeout)
        while true {
            let status = try watcher.status(projectRoot: root)
            if wait == nil || status.fresh {
                FileHandle.standardOutput.write(try status.jsonData())
                return
            }
            guard Date() < deadline else {
                FileHandle.standardError.write(Data("timed out waiting for a fresh indexed project generation\n".utf8))
                throw ExitCode.failure
            }
            Thread.sleep(forTimeInterval: 0.25)
        }
    }
}

struct ProjectStop: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "stop",
        abstract: "Stop the managed watcher for one configured project."
    )

    @Argument(help: "Project root.") var path: String = "."
    @Option(name: .long, help: "Output format.") var format: ProjectOutputFormat?

    mutating func run() throws {
        let root = URL(fileURLWithPath: path, isDirectory: true).standardizedFileURL.resolvingSymlinksInPath()
        let result = try ProjectServiceController().stop(projectRoot: root)
        FileHandle.standardOutput.write(try result.jsonData())
    }
}

struct ProjectBaseline: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "baseline",
        abstract: "Manage the Git-trackable semantic project baseline.",
        subcommands: [ProjectBaselineUpdate.self]
    )
}

struct ProjectBaselineUpdate: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Promote the fresh indexed live snapshot to the project baseline."
    )

    @Argument(help: "Project root.") var path: String = "."
    @Option(name: .long, help: "Output format.") var format: ProjectOutputFormat?

    mutating func run() throws {
        let status = try WatcherCoordinator().promoteBaseline(
            projectRoot: URL(fileURLWithPath: path, isDirectory: true)
        )
        FileHandle.standardOutput.write(try status.jsonData())
    }
}
