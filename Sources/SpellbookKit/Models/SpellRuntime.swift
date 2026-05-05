public struct SpellRuntime: Equatable, Sendable {
    public let override: Bool
    public let silent: Bool
    public let workingDir: String?
    public let shell: String?

    public init(
        override: Bool = false,
        silent: Bool = false,
        workingDir: String? = nil,
        shell: String? = nil
    ) {
        self.override = override
        self.silent = silent
        self.workingDir = workingDir
        self.shell = shell
    }

    public static let `default` = SpellRuntime()
}
