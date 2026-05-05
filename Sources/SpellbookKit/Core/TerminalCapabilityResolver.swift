public enum TerminalCapabilityResolver {
    public static func resolve(
        isTTY: Bool,
        noColorValue: String?,
        termValue: String?
    ) -> TerminalCapabilities {
        let isDumb = termValue == "dumb"
        let noColorSet = noColorValue != nil
        let supportsColor = isTTY && !noColorSet && !isDumb
        let supportsRawMode = isTTY && !isDumb
        return TerminalCapabilities(
            isTTY: isTTY,
            supportsColor: supportsColor,
            supportsRawMode: supportsRawMode
        )
    }
}
