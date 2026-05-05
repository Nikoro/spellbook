enum ParamName {
    static func isValid(_ name: String) -> Bool {
        guard let first = name.first, isHead(first) else { return false }
        return name.dropFirst().allSatisfy(isBody)
    }

    private static func isHead(_ char: Character) -> Bool {
        AsciiClass.isLetter(char) || char == "_"
    }

    private static func isBody(_ char: Character) -> Bool {
        AsciiClass.isLetter(char) || AsciiClass.isDigit(char) || char == "_"
    }
}
