import Testing
@testable import SpellbookKit

struct CompletionResolverTests {

    @Test func zsh_includesCompdef() throws {
        let script = try CompletionResolver.script(shell: "zsh")
        #expect(script.contains("compdef _spells spells"))
        #expect(script.contains("run:Invoke a spell"))
    }

    @Test func bash_includesComplete() throws {
        let script = try CompletionResolver.script(shell: "bash")
        #expect(script.contains("complete -F _spells_completion spells"))
        #expect(script.contains("run list diff doctor"))
    }

    @Test func fish_usesFishSubcommand() throws {
        let script = try CompletionResolver.script(shell: "fish")
        #expect(script.contains("__fish_use_subcommand"))
        #expect(script.contains("__fish_seen_subcommand_from help clean"))
    }

    @Test func unsupportedShell_throws() {
        #expect(throws: SpellbookError.unsupportedShell(name: "pwsh")) {
            try CompletionResolver.script(shell: "pwsh")
        }
    }

    @Test func missingShell_throws() {
        #expect(throws: SpellbookError.completionMissingShell) {
            try CompletionCommand().run(shell: nil)
        }
    }
}
