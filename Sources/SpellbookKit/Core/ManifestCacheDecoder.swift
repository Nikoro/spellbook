import Foundation

extension ManifestCacheReader {
    mutating func readManifest() -> SpellbookManifest? {
        guard let versionRaw = readU32() else { return nil }
        guard let extendsBox = readOptionalString() else { return nil }
        guard let spellCount = readU32() else { return nil }
        var spells: [SpellDefinition] = []
        spells.reserveCapacity(Int(spellCount))
        for _ in 0..<Int(spellCount) {
            guard let spell = readSpell() else { return nil }
            spells.append(spell)
        }
        return SpellbookManifest(
            version: Int(versionRaw), extends: extendsBox.value, spells: spells
        )
    }

    mutating func readSpell() -> SpellDefinition? {
        guard let name = readString() else { return nil }
        guard let descBox = readOptionalString() else { return nil }
        guard let aliases = readStringList() else { return nil }
        guard let scriptBox = readOptionalString() else { return nil }
        guard let paramCount = readU32() else { return nil }
        var params: [ParamDefinition] = []
        params.reserveCapacity(Int(paramCount))
        for _ in 0..<Int(paramCount) {
            guard let param = readParam() else { return nil }
            params.append(param)
        }
        guard let switchBranches = readOptionalSwitch() else { return nil }
        guard let runtime = readRuntime() else { return nil }
        return SpellDefinition(
            identity: SpellIdentity(
                name: name, description: descBox.value, aliases: aliases
            ),
            body: SpellBody(
                script: scriptBox.value, params: params, switchBranches: switchBranches
            ),
            runtime: runtime
        )
    }

    mutating func readParam() -> ParamDefinition? {
        guard let name = readString() else { return nil }
        guard let descBox = readOptionalString() else { return nil }
        guard let isRequired = readBool() else { return nil }
        guard let isPositional = readBool() else { return nil }
        guard let flags = readStringList() else { return nil }
        guard let typeCode = readU8() else { return nil }
        guard let type = ManifestCacheTypes.paramType(for: typeCode) else { return nil }
        guard let values = readStringList() else { return nil }
        guard let defaultBox = readOptionalString() else { return nil }
        return ParamDefinition(
            name: name,
            description: descBox.value,
            shape: ParamShape(
                isRequired: isRequired, isPositional: isPositional, flags: flags
            ),
            schema: ParamSchema(type: type, values: values, defaultValue: defaultBox.value)
        )
    }

    mutating func readOptionalSwitch() -> SwitchDefinition?? {
        guard let flag = readBool() else { return nil }
        if !flag { return .some(nil) }
        guard let count = readU32() else { return nil }
        var options: [SwitchOptionDefinition] = []
        options.reserveCapacity(Int(count))
        for _ in 0..<Int(count) {
            guard let option = readSwitchOption() else { return nil }
            options.append(option)
        }
        guard let branch = readDefaultBranch() else { return nil }
        return .some(SwitchDefinition(options: options, defaultBranch: branch))
    }

    mutating func readSwitchOption() -> SwitchOptionDefinition? {
        guard let name = readString() else { return nil }
        guard let aliases = readStringList() else { return nil }
        guard let descBox = readOptionalString() else { return nil }
        guard let command = readSpell() else { return nil }
        return SwitchOptionDefinition(
            name: name, aliases: aliases, description: descBox.value, command: command
        )
    }

    mutating func readDefaultBranch() -> DefaultBranch? {
        guard let tag = readU8() else { return nil }
        switch tag {
        case 0: return DefaultBranch.none
        case 1:
            guard let key = readString() else { return nil }
            return DefaultBranch.key(key)
        case 2:
            guard let command = readSpell() else { return nil }
            return DefaultBranch.inline(command)
        default:
            return nil
        }
    }

    mutating func readRuntime() -> SpellRuntime? {
        guard let override = readBool() else { return nil }
        guard let silent = readBool() else { return nil }
        guard let workingBox = readOptionalString() else { return nil }
        guard let shellBox = readOptionalString() else { return nil }
        return SpellRuntime(
            override: override, silent: silent,
            workingDir: workingBox.value, shell: shellBox.value
        )
    }
}
