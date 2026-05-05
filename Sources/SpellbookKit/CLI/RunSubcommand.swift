import Foundation

enum RunSubcommand {
    struct Context {
        let spellbookHome: String
        let home: String?
        let capabilities: TerminalCapabilities
        let onError: (Error) -> Never
    }

    static func execute(arguments: [String], context: Context) {
        let fileSystem = FoundationFileSystem()
        let terminal = StandardTerminal(capabilities: context.capabilities)
        let pathEnv = ProcessInfo.processInfo.environment["PATH"] ?? ""
        let overrideLookup = OverrideResolver(
            pathDirectories: pathEnv.split(separator: ":").map(String.init),
            spellbookBin: context.spellbookHome + "/bin",
            fileSystem: fileSystem
        )
        let runResolver = RunResolver(
            fileSystem: fileSystem,
            manifestReader: FoundationManifestReader(),
            manifestLoader: FoundationManifestLoader(fileSystem: fileSystem),
            overrideLookup: overrideLookup,
            choiceProvider: TerminalChoiceProvider(terminal: terminal),
            home: context.home
        )
        let silentRunner = SilentRunner(
            terminal: terminal,
            capturingRunner: FoundationCapturingRunner(),
            scriptExecutor: ScriptExecutor(processRunner: FoundationProcessRunner())
        )
        let command = RunCommand(
            resolver: runResolver,
            silentRunner: silentRunner,
            stateStore: StateFile(path: context.spellbookHome + "/state.json")
        )
        do { exit(try command.run(arguments: arguments)) } catch { context.onError(error) }
    }
}
