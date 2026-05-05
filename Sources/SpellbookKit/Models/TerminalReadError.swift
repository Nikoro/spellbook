public enum TerminalReadError: Error, Sendable {
    case noInput
    case rawModeUnavailable
}
