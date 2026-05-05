import Testing
@testable import SpellbookKit

struct InitResolverTests {

    @Test func zsh_emitsPhase3Integration() throws {
        let snippet = try InitResolver.shellSnippet(shell: "zsh")
        #expect(snippet.contains("SPELLBOOK_HOME/bin"))
        #expect(snippet.contains("_spells_zle_complete"))
    }

    @Test func bash_emitsPhase3Integration() throws {
        let snippet = try InitResolver.shellSnippet(shell: "bash")
        #expect(snippet.contains("SPELLBOOK_HOME/bin"))
        #expect(snippet.contains("_spells_tab_complete"))
    }

    @Test func fish_emitsPhase3Integration() throws {
        let snippet = try InitResolver.shellSnippet(shell: "fish")
        #expect(snippet.contains("SPELLBOOK_HOME/bin"))
        #expect(snippet.contains("commandline"))
    }

    @Test func unknownShell_throwsError() {
        #expect(throws: SpellbookError.unsupportedShell(name: "nushell")) {
            try InitResolver.shellSnippet(shell: "nushell")
        }
    }

    @Test func allSnippets_includeVersionMarker() throws {
        for shell in ["zsh", "bash", "fish"] {
            let snippet = try InitResolver.shellSnippet(shell: shell)
            #expect(snippet.contains("Spellbook integration v"), "Missing marker: \(shell)")
        }
    }
}
