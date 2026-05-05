public enum ErrorTemplates {
    public static func header(
        _ text: String,
        color: Bool
    ) -> String {
        let label = ANSIColors.wrap("error:", in: ANSIColors.bold + ANSIColors.red, color: color)
        return "\(label) \(text)"
    }

    public static func context(
        _ text: String,
        color: Bool
    ) -> String {
        let arrow = ANSIColors.wrap("-->", in: ANSIColors.dim, color: color)
        return "  \(arrow) \(text)"
    }

    public static func caret(
        column: Int,
        color: Bool
    ) -> String {
        let padding = String(repeating: " ", count: max(0, column - 1))
        let marker = ANSIColors.wrap("^", in: ANSIColors.red, color: color)
        return "      \(padding)\(marker)"
    }

    public static func body(_ text: String) -> String {
        "  \(text)"
    }

    public static func suggestion(
        _ text: String,
        color: Bool
    ) -> String {
        let label = ANSIColors.wrap("tip:", in: ANSIColors.cyan, color: color)
        return "\(label) \(text)"
    }

    public static func compose(
        header: String,
        context: String? = nil,
        body: String? = nil,
        suggestion: String? = nil
    ) -> String {
        ([header] + [context, body, suggestion].compactMap { $0 })
            .joined(separator: "\n")
    }
}
