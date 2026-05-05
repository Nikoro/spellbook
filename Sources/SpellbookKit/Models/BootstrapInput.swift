public struct BootstrapInput: Sendable {
    public let pathEnv: String?
    public let spellbookBinDir: String
    public let shell: String?
    public let home: String?
    public let isTTY: Bool
    public let rcFileContent: String?

    public init(
        pathEnv: String?,
        spellbookBinDir: String,
        shell: String?,
        home: String?,
        isTTY: Bool,
        rcFileContent: String?
    ) {
        self.pathEnv = pathEnv
        self.spellbookBinDir = spellbookBinDir
        self.shell = shell
        self.home = home
        self.isTTY = isTTY
        self.rcFileContent = rcFileContent
    }
}
