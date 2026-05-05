public struct InitCommand {
    public init() {}

    public func run(shell: String?) throws -> String {
        guard let shell else {
            throw SpellbookError.initMissingShell
        }
        return try InitResolver.shellSnippet(shell: shell)
    }
}
