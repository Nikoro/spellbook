enum AsciiClass {
    static func isLetter(_ char: Character) -> Bool {
        ("a"..."z").contains(char) || ("A"..."Z").contains(char)
    }

    static func isDigit(_ char: Character) -> Bool {
        ("0"..."9").contains(char)
    }
}
