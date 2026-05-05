import Foundation

struct ManifestCacheWriter {
    private(set) var data = Data()

    mutating func appendBytes(_ bytes: [UInt8]) {
        data.append(contentsOf: bytes)
    }

    mutating func appendU16(_ value: UInt16) {
        data.append(UInt8(value >> 8 & 0xFF))
        data.append(UInt8(value & 0xFF))
    }

    mutating func appendU32(_ value: UInt32) {
        data.append(UInt8(value >> 24 & 0xFF))
        data.append(UInt8(value >> 16 & 0xFF))
        data.append(UInt8(value >> 8 & 0xFF))
        data.append(UInt8(value & 0xFF))
    }

    mutating func appendU8(_ value: UInt8) { data.append(value) }

    mutating func appendBool(_ value: Bool) { data.append(value ? 1 : 0) }

    mutating func appendString(_ value: String) {
        let bytes = Array(value.utf8)
        appendU32(UInt32(bytes.count))
        data.append(contentsOf: bytes)
    }

    mutating func appendOptionalString(_ value: String?) {
        if let value = value {
            appendBool(true)
            appendString(value)
        } else {
            appendBool(false)
        }
    }

    mutating func appendStringList(_ values: [String]) {
        appendU16(UInt16(values.count))
        for value in values { appendString(value) }
    }

    mutating func appendManifest(_ manifest: SpellbookManifest) {
        appendU32(UInt32(manifest.version))
        appendOptionalString(manifest.extends)
        appendU32(UInt32(manifest.spells.count))
        for spell in manifest.spells { appendSpell(spell) }
    }

    mutating func appendSpell(_ spell: SpellDefinition) {
        appendString(spell.name)
        appendOptionalString(spell.description)
        appendStringList(spell.aliases)
        appendOptionalString(spell.script)
        appendU32(UInt32(spell.params.count))
        for param in spell.params { appendParam(param) }
        appendOptionalSwitch(spell.switchBranches)
        appendRuntime(spell.runtime)
    }

    mutating func appendParam(_ param: ParamDefinition) {
        appendString(param.name)
        appendOptionalString(param.description)
        appendBool(param.shape.isRequired)
        appendBool(param.shape.isPositional)
        appendStringList(param.shape.flags)
        appendU8(ManifestCacheTypes.paramTypeCode(param.schema.type))
        appendStringList(param.schema.values)
        appendOptionalString(param.schema.defaultValue)
    }

    mutating func appendOptionalSwitch(_ switchDef: SwitchDefinition?) {
        guard let switchDef = switchDef else {
            appendBool(false)
            return
        }
        appendBool(true)
        appendU32(UInt32(switchDef.options.count))
        for option in switchDef.options { appendSwitchOption(option) }
        appendDefaultBranch(switchDef.defaultBranch)
    }

    mutating func appendSwitchOption(_ option: SwitchOptionDefinition) {
        appendString(option.name)
        appendStringList(option.aliases)
        appendOptionalString(option.description)
        appendSpell(option.command)
    }

    mutating func appendDefaultBranch(_ branch: DefaultBranch) {
        switch branch {
        case .none:
            appendU8(0)
        case .key(let key):
            appendU8(1)
            appendString(key)
        case .inline(let command):
            appendU8(2)
            appendSpell(command)
        }
    }

    mutating func appendRuntime(_ runtime: SpellRuntime) {
        appendBool(runtime.override)
        appendBool(runtime.silent)
        appendOptionalString(runtime.workingDir)
        appendOptionalString(runtime.shell)
    }
}
