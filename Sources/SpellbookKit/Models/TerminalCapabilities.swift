public struct TerminalCapabilities: Equatable, Sendable {
    public let isTTY: Bool
    public let supportsColor: Bool
    public let supportsRawMode: Bool

    public init(
        isTTY: Bool,
        supportsColor: Bool,
        supportsRawMode: Bool
    ) {
        self.isTTY = isTTY
        self.supportsColor = supportsColor
        self.supportsRawMode = supportsRawMode
    }
}
