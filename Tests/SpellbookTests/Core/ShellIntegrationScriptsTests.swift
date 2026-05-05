import Testing
@testable import SpellbookKit

struct ShellIntegrationScriptsTests {

    // MARK: zsh

    @Test func zsh_containsVersionMarker() {
        let script = ShellIntegrationScripts.script(for: .zsh)
        #expect(script.contains("# Spellbook integration v"))
    }

    @Test func zsh_installsZleWidget() {
        let script = ShellIntegrationScripts.script(for: .zsh)
        #expect(script.contains("_spells_zle_complete"))
        #expect(script.contains("zle -N _spells_zle_complete"))
        #expect(script.contains("bindkey"))
    }

    @Test func zsh_callsSpellsComplete() {
        let script = ShellIntegrationScripts.script(for: .zsh)
        #expect(script.contains("spells complete"))
        #expect(script.contains("--cword"))
    }

    @Test func zsh_handlesFallthrough() {
        let script = ShellIntegrationScripts.script(for: .zsh)
        #expect(script.contains("__SPELLBOOK_FALLTHROUGH__"))
        #expect(script.contains("expand-or-complete"))
    }

    @Test func zsh_resumesPickerInPrecmd() {
        // The widget defers multi-candidate picker execution to precmd so
        // zle releases the terminal while the picker runs.
        let script = ShellIntegrationScripts.script(for: .zsh)
        #expect(script.contains("_spells_resume_picker"))
        #expect(script.contains("add-zsh-hook precmd"))
        #expect(script.contains("print -z"))
    }

    @Test func zsh_bootstrapsPath() {
        let script = ShellIntegrationScripts.script(for: .zsh)
        #expect(script.contains("SPELLBOOK_HOME/bin"))
    }

    // MARK: bash

    @Test func bash_containsVersionMarker() {
        let script = ShellIntegrationScripts.script(for: .bash)
        #expect(script.contains("# Spellbook integration v"))
    }

    @Test func bash_bindsTabToHandler() {
        let script = ShellIntegrationScripts.script(for: .bash)
        #expect(script.contains("_spells_tab_complete"))
        #expect(script.contains("bind -x"))
        #expect(script.contains("READLINE_LINE"))
    }

    @Test func bash_hasFallthroughHandling() {
        let script = ShellIntegrationScripts.script(for: .bash)
        #expect(script.contains("__SPELLBOOK_FALLTHROUGH__"))
    }

    @Test func bash_bootstrapsPath() {
        let script = ShellIntegrationScripts.script(for: .bash)
        #expect(script.contains("SPELLBOOK_HOME/bin"))
    }

    // MARK: fish

    @Test func fish_containsVersionMarker() {
        let script = ShellIntegrationScripts.script(for: .fish)
        #expect(script.contains("# Spellbook integration v"))
    }

    @Test func fish_bindsTabToHandler() {
        let script = ShellIntegrationScripts.script(for: .fish)
        #expect(script.contains("__spells_tab_complete"))
        #expect(script.contains("bind \\t"))
    }

    @Test func fish_usesCommandline() {
        let script = ShellIntegrationScripts.script(for: .fish)
        #expect(script.contains("commandline"))
    }

    @Test func fish_bootstrapsPath() {
        let script = ShellIntegrationScripts.script(for: .fish)
        #expect(script.contains("SPELLBOOK_HOME/bin"))
    }

    @Test func fish_hasFallthroughHandling() {
        let script = ShellIntegrationScripts.script(for: .fish)
        #expect(script.contains("__SPELLBOOK_FALLTHROUGH__"))
    }

    // MARK: custom picker wiring (FR-39)

    @Test func zsh_routesMultipleCandidatesThroughSpellsPick() {
        let script = ShellIntegrationScripts.script(for: .zsh)
        #expect(script.contains("spells pick"))
    }

    @Test func bash_routesMultipleCandidatesThroughSpellsPick() {
        let script = ShellIntegrationScripts.script(for: .bash)
        #expect(script.contains("spells pick"))
    }

    @Test func fish_routesMultipleCandidatesThroughSpellsPick() {
        let script = ShellIntegrationScripts.script(for: .fish)
        #expect(script.contains("spells pick"))
    }
}
