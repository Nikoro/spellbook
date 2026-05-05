import Foundation

public enum SpellbookApp {
    static let reservedSubcommands: Set<String> = [
        "run", "list", "doctor", "create", "init", "diff", "clean",
        "completion", "complete", "pick", "version", "help"
    ]

    public static func run(arguments: [String]) {
        let invocation = Array(arguments.dropFirst())
        guard let first = invocation.first else { activateProject(); return }
        let rest = Array(invocation.dropFirst())
        if ["--version", "-v", "version"].contains(first) {
            print(SpellbookVersion.current); return
        }
        if ["--help", "-h", "help"].contains(first) { showHelp(rest); return }
        dispatch(subcommand: first, rest: rest)
    }

    private static func dispatch(subcommand: String, rest: [String]) {
        if handleNonInteractive(subcommand: subcommand, rest: rest) { return }
        switch subcommand {
        case "diff": runDiff()
        case "clean": runClean(rest)
        case "completion": runCompletion(rest)
        case "complete": runComplete(rest)
        case "pick": PickSubcommand.run()
        default: Self.fail("unknown subcommand `\(subcommand)`. Try `spells --help`.")
        }
    }

    private static func handleNonInteractive(
        subcommand: String, rest: [String]
    ) -> Bool {
        switch subcommand {
        case "run": runSpell(rest)
        case "list": listSpells(rest)
        case "doctor": runDoctor(rest)
        case "create": createManifest(rest)
        case "init": initShell(rest)
        default: return false
        }
        return true
    }

    private static var home: String? { ProcessInfo.processInfo.environment["HOME"] }
    private static var spellbookHome: String {
        ProcessInfo.processInfo.environment["SPELLBOOK_HOME"]
            ?? home.map { $0 + "/.spellbook" } ?? ""
    }
    private static var cwd: String { FileManager.default.currentDirectoryPath }

    private static func makeResolver() -> ActivationResolver {
        let fileSystem = FoundationFileSystem()
        return ActivationResolver(
            fileSystem: fileSystem, manifestReader: FoundationManifestReader(),
            manifestLoader: FoundationManifestLoader(fileSystem: fileSystem),
            pathChecker: DefaultPathChecker.make(spellbookHome: spellbookHome),
            home: home
        )
    }

    private static func makeCacheWriter() -> ManifestCacheWriterAdapter {
        ManifestCacheWriterAdapter(spellbookHome: spellbookHome)
    }

    private static func activateProject() {
        let binDir = spellbookHome + "/bin"
        let command = ActivationCommand(
            resolver: makeResolver(),
            wrapperGenerator: WrapperGenerator(writer: AtomicWrapperWriter(), binDirectory: binDir),
            stateStore: StateFile(path: spellbookHome + "/state.json"),
            manifestContent: FoundationManifestContentReader(),
            cacheWriter: makeCacheWriter(),
            fileLock: PosixFileLock(path: spellbookHome + "/state.lock")
        )
        do {
            let summary = try command.activate(cwd: cwd)
            let tag = summary.source == .homeFallback ? " (home fallback)" : ""
            print("Activated \(summary.spellCount) spells, \(summary.wrapperCount) wrappers\(tag)")
            for line in ActivationSummaryRenderer.renderChanges(summary.changes) { print(line) }
        } catch { Self.fail(renderError(error)) }
        BootstrapSubcommand.check(
            binDir: binDir, home: home,
            capabilities: capabilities(for: STDIN_FILENO)
        )
    }

    private static func runSpell(_ arguments: [String]) {
        RunSubcommand.execute(
            arguments: arguments,
            context: RunSubcommand.Context(
                spellbookHome: spellbookHome,
                home: home,
                capabilities: capabilities(for: STDOUT_FILENO),
                onError: { Self.fail(renderError($0)) }
            )
        )
    }

    private static func capabilities(for fileDescriptor: Int32) -> TerminalCapabilities {
        let env = ProcessInfo.processInfo.environment
        return TerminalCapabilityResolver.resolve(
            isTTY: isatty(fileDescriptor) != 0,
            noColorValue: env["NO_COLOR"], termValue: env["TERM"])
    }

    private static func listSpells(_ arguments: [String]) {
        let verbose = arguments.contains("--verbose") || arguments.contains("-v")
        let command = ListCommand(
            resolver: makeResolver(), verbose: verbose, cacheWriter: makeCacheWriter()
        )
        do { for line in try command.run(cwd: cwd) { print(line) } } catch { Self.fail(renderError(error)) }
    }

    private static func runDoctor(_ arguments: [String]) {
        StateSubcommands.runDoctor(
            arguments: arguments, context: stateContext(), binDir: spellbookHome + "/bin"
        )
    }

    private static func stateContext() -> StateSubcommands.Context {
        StateSubcommands.Context(
            resolver: makeResolver(),
            stateStore: StateFile(path: spellbookHome + "/state.json"),
            cwd: cwd,
            onError: { Self.fail(renderError($0)) },
            cacheWriter: makeCacheWriter()
        )
    }

    private static func runDiff() { StateSubcommands.runDiff(context: stateContext()) }

    private static func runClean(_ arguments: [String]) {
        StateSubcommands.runClean(
            arguments: arguments,
            context: stateContext(),
            wrapperWriter: AtomicWrapperWriter()
        )
    }

    private static func createManifest(_ arguments: [String]) {
        let command = CreateCommand(
            fileSystem: FoundationFileSystem(),
            fileWriter: FoundationFileWriter()
        )
        do {
            let path = try command.run(cwd: cwd, spellName: arguments.first)
            print("Created \(path)")
        } catch { Self.fail(renderError(error)) }
    }

    private static func showHelp(_ arguments: [String]) {
        let context = SpellbookAppHelp.Context(
            resolver: makeResolver(), cwd: cwd,
            renderError: renderError, fail: Self.fail
        )
        SpellbookAppHelp.show(arguments: arguments, context: context)
    }

    private static func initShell(_ arguments: [String]) {
        do { print(try InitCommand().run(shell: arguments.first)) } catch { Self.fail(renderError(error)) }
    }

    private static func runCompletion(_ arguments: [String]) {
        do { print(try CompletionCommand().run(shell: arguments.first)) } catch { Self.fail(renderError(error)) }
    }

    private static func runComplete(_ arguments: [String]) {
        let context = CompleteSubcommand.Context(
            resolver: makeResolver(),
            cacheReader: ManifestCacheReaderAdapter(spellbookHome: spellbookHome),
            cacheWriter: makeCacheWriter(),
            cwd: cwd
        )
        CompleteSubcommand.run(arguments: arguments, context: context)
    }

    private static var stderrColor: Bool { capabilities(for: STDERR_FILENO).supportsColor }

    static func renderError(_ error: Error) -> String {
        guard let spellErr = error as? SpellbookError else { return "\(error)" }
        return ErrorReporter.render(spellErr, color: stderrColor)
    }

    private static func fail(_ message: String) -> Never {
        FileHandle.standardError.write(Data("\(message)\n".utf8))
        exit(1)
    }
}
