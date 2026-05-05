public enum ANSIColors {
    static let reset = "\u{1B}[0m"
    static let bold = "\u{1B}[1m"
    static let dim = "\u{1B}[2m"
    static let red = "\u{1B}[31m"
    static let yellow = "\u{1B}[33m"
    static let cyan = "\u{1B}[36m"

    public static func wrap(
        _ text: String,
        in code: String,
        color: Bool
    ) -> String {
        guard color else { return text }
        return code + text + reset
    }
}
