public struct RunCommand {
    private let resolver: RunResolver
    private let silentRunner: SilentRunner
    private let stateStore: StateStore

    public init(
        resolver: RunResolver,
        silentRunner: SilentRunner,
        stateStore: StateStore
    ) {
        self.resolver = resolver
        self.silentRunner = silentRunner
        self.stateStore = stateStore
    }

    public func run(arguments: [String]) throws -> Int32 {
        let parsed = try Self.parseArguments(arguments)
        let prepared: PreparedSpell
        do {
            prepared = try resolver.resolve(
                spellName: parsed.spellName,
                argv: parsed.spellArgv,
                cwd: parsed.cwd
            )
        } catch let error as SpellbookError where error == .spellNotFound(name: parsed.spellName) {
            throw enhanceWithDiagnostics(spellName: parsed.spellName, original: error)
        }
        return try silentRunner.execute(spell: prepared)
    }

    private func enhanceWithDiagnostics(
        spellName: String,
        original: SpellbookError
    ) -> SpellbookError {
        let state = try? stateStore.read()
        let result = StaleDiagnostic.diagnose(spellName: spellName, state: state)
        switch result {
        case .foundInProjects(let matches):
            return .spellNotFoundWithSuggestions(
                name: spellName,
                projects: matches.map(\.projectPath)
            )
        case .noState, .notFoundAnywhere:
            return original
        }
    }

    struct ParsedArgs {
        let spellName: String
        let cwd: String
        let spellArgv: [String]
    }

    static func parseArguments(_ arguments: [String]) throws -> ParsedArgs {
        guard let spellName = arguments.first else {
            throw SpellbookError.runMissingSpellName
        }
        let (cwd, spellArgv) = try scanArguments(Array(arguments.dropFirst()))
        guard let resolvedCwd = cwd else {
            throw SpellbookError.runMissingCwd
        }
        return ParsedArgs(spellName: spellName, cwd: resolvedCwd, spellArgv: spellArgv)
    }

    private static func scanArguments(
        _ args: [String]
    ) throws -> (cwd: String?, argv: [String]) {
        var cwd: String?
        var spellArgv: [String] = []
        var index = 0
        var pastSentinel = false

        while index < args.count {
            let arg = args[index]
            if pastSentinel {
                spellArgv.append(arg)
            } else if arg == "--" {
                pastSentinel = true
            } else if arg == "--cwd" {
                index += 1
                guard index < args.count else { throw SpellbookError.runMissingCwd }
                cwd = args[index]
            }
            index += 1
        }
        return (cwd, spellArgv)
    }
}
