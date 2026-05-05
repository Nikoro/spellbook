public struct CompletionCommand {
    public init() {}

    public func run(shell: String?) throws -> String {
        guard let shell else { throw SpellbookError.completionMissingShell }
        return try CompletionResolver.script(shell: shell)
    }
}
