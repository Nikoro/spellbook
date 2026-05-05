enum SpellName {
    static func isValid(_ name: String) -> Bool {
        guard let first = name.first, AsciiClass.isLetter(first) else { return false }
        return name.dropFirst().allSatisfy(isBody)
    }

    private static func isBody(_ char: Character) -> Bool {
        AsciiClass.isLetter(char) || AsciiClass.isDigit(char) || char == "_" || char == "-"
    }
}
