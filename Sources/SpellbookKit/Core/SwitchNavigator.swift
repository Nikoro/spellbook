public struct SwitchNavigator {
    public struct Resolution: Equatable {
        public let terminal: SpellDefinition
        public let remainingArgv: [String]

        public init(terminal: SpellDefinition, remainingArgv: [String]) {
            self.terminal = terminal
            self.remainingArgv = remainingArgv
        }
    }

    private let choiceProvider: FiniteChoiceProvider?

    public init(choiceProvider: FiniteChoiceProvider? = nil) {
        self.choiceProvider = choiceProvider
    }

    public func resolve(
        spell: SpellDefinition,
        argv: [String],
        spellName: String
    ) throws -> Resolution {
        guard let switchDef = spell.switchBranches else {
            return Resolution(terminal: spell, remainingArgv: argv)
        }

        if let firstArg = argv.first,
           let option = findOption(firstArg, in: switchDef) {
            return try resolve(
                spell: option.command,
                argv: Array(argv.dropFirst()),
                spellName: spellName
            )
        }

        return try resolveDefault(switchDef, argv: argv, spellName: spellName)
    }

    private func resolveDefault(
        _ switchDef: SwitchDefinition,
        argv: [String],
        spellName: String
    ) throws -> Resolution {
        switch switchDef.defaultBranch {
        case .key(let key):
            return try resolveDefaultKey(
                key, switchDef: switchDef, argv: argv, spellName: spellName
            )
        case .inline(let command):
            return try resolve(spell: command, argv: argv, spellName: spellName)
        case .none:
            if let picked = try pickSwitchOption(switchDef, argv: argv, spellName: spellName) {
                return picked
            }
            throw noMatchError(argv: argv, switchDef: switchDef, spellName: spellName)
        }
    }

    private func resolveDefaultKey(
        _ key: String,
        switchDef: SwitchDefinition,
        argv: [String],
        spellName: String
    ) throws -> Resolution {
        if let option = switchDef.options.first(where: { $0.name == key }) {
            return try resolve(
                spell: option.command, argv: argv, spellName: spellName
            )
        }
        throw SpellbookError.switchRequiresOption(
            spell: spellName, available: switchDef.options.map(\.name)
        )
    }

    private func pickSwitchOption(
        _ switchDef: SwitchDefinition,
        argv: [String],
        spellName: String
    ) throws -> Resolution? {
        guard argv.isEmpty, let provider = choiceProvider else { return nil }
        let options = switchDef.options.map(\.name)
        let outcome = try provider.choose(options: options, prompt: spellName)
        switch outcome {
        case .selected(let idx):
            return try resolve(
                spell: switchDef.options[idx].command,
                argv: argv,
                spellName: spellName
            )
        case .cancelled:
            throw SpellbookError.selectionCancelled(spell: spellName)
        case .unavailable:
            return nil
        }
    }

    private func noMatchError(
        argv: [String],
        switchDef: SwitchDefinition,
        spellName: String
    ) -> SpellbookError {
        let available = switchDef.options.map(\.name)
        if let firstArg = argv.first {
            return .switchOptionNotFound(
                spell: spellName, option: firstArg, available: available
            )
        }
        return .switchRequiresOption(spell: spellName, available: available)
    }

    private func findOption(
        _ name: String,
        in switchDef: SwitchDefinition
    ) -> SwitchOptionDefinition? {
        switchDef.options.first { $0.name == name || $0.aliases.contains(name) }
    }
}
