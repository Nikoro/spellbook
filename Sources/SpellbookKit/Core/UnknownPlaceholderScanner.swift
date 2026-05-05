import Foundation

enum UnknownPlaceholderScanner {
    static func unknownReferences(
        in spell: SpellDefinition,
        scripts: [String]
    ) -> [String] {
        let known = knownIdentifiers(for: spell)
        var unknown: Set<String> = []
        for script in scripts {
            for match in placeholders(in: script) where !known.contains(match) {
                unknown.insert(match)
            }
        }
        return unknown.sorted()
    }

    private static func knownIdentifiers(for spell: SpellDefinition) -> Set<String> {
        var known = Set(spell.params.map(\.name))
        if spell.override { known.insert(spell.name) }
        return known
    }

    private static func placeholders(in script: String) -> [String] {
        var matches: [String] = []
        var remaining = script[...]
        while let range = remaining.range(of: "{{") {
            let afterOpen = remaining[range.upperBound...]
            guard let close = afterOpen.range(of: "}}") else { break }
            let body = afterOpen[afterOpen.startIndex..<close.lowerBound]
            if isIdentifier(body) {
                matches.append(String(body))
            }
            remaining = afterOpen[close.upperBound...]
        }
        return matches
    }

    private static func isIdentifier(_ body: Substring) -> Bool {
        guard !body.isEmpty else { return false }
        return body.allSatisfy { character in
            AsciiClass.isLetter(character) || AsciiClass.isDigit(character)
                || character == "_" || character == "-"
        }
    }
}
