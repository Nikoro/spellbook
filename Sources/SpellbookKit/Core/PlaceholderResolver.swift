public struct PlaceholderResolver {
    public init() {}

    public func resolve(
        script: String,
        spell: SpellDefinition,
        arguments: ParsedArguments,
        overrideLookup: OverrideLookup? = nil
    ) -> String {
        let script = expandPassthrough(in: script, arguments: arguments)
        var output = ""
        var cursor = script.startIndex

        while cursor < script.endIndex {
            guard let range = nextPlaceholder(in: script, from: cursor) else {
                output.append(contentsOf: script[cursor...])
                break
            }

            output.append(contentsOf: script[cursor..<range.lowerBound])
            let token = String(script[range])
            output.append(
                replacement(
                    for: token,
                    spell: spell,
                    arguments: arguments,
                    overrideLookup: overrideLookup
                ) ?? token
            )
            cursor = range.upperBound
        }

        return output
    }

    private func expandPassthrough(in script: String, arguments: ParsedArguments) -> String {
        let replacement = arguments.passthrough.map(shellEscape).joined(separator: " ")
        return replacingOccurrences(of: "...args", with: replacement, in: script)
    }

    private func nextPlaceholder(
        in script: String,
        from start: String.Index
    ) -> Range<String.Index>? {
        guard let open = script[start...].range(of: "{{") else { return nil }
        guard let close = script[open.upperBound...].range(of: "}}") else { return nil }
        return open.lowerBound..<close.upperBound
    }

    private func replacement(
        for token: String,
        spell: SpellDefinition,
        arguments: ParsedArguments,
        overrideLookup: OverrideLookup?
    ) -> String? {
        guard token.hasPrefix("{{"), token.hasSuffix("}}") else { return nil }
        let name = String(token.dropFirst(2).dropLast(2))

        if ParamName.isValid(name),
           let param = spell.params.first(where: { $0.name == name }) {
            let value = arguments.values[name]
                ?? param.defaultValue
                ?? param.type.zero
            return shellEscape(value)
        }

        if spell.override, SpellName.isValid(name), name == spell.name,
           let path = overrideLookup?.externalCommand(for: name) {
            return shellEscape(path)
        }

        return nil
    }

    private func shellEscape(_ token: String) -> String {
        guard !token.isEmpty else { return "''" }

        var escaped = "'"
        for character in token {
            if character == "'" {
                escaped.append(contentsOf: "'\\''")
            } else {
                escaped.append(character)
            }
        }
        escaped.append("'")
        return escaped
    }

    private func replacingOccurrences(
        of needle: String,
        with replacement: String,
        in source: String
    ) -> String {
        var output = ""
        var cursor = source.startIndex

        while let range = source[cursor...].range(of: needle) {
            output.append(contentsOf: source[cursor..<range.lowerBound])
            output.append(contentsOf: replacement)
            cursor = range.upperBound
        }

        output.append(contentsOf: source[cursor...])
        return output
    }
}
