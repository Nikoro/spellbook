public enum CompletionResolver {
    public static func script(shell: String) throws -> String {
        switch shell {
        case "zsh": return zshScript
        case "bash": return bashScript
        case "fish": return fishScript
        default: throw SpellbookError.unsupportedShell(name: shell)
        }
    }

    private static let zshScript = """
    # spellbook zsh completion
    # source this file or place it on $fpath.
    _spells() {
        local -a subs
        subs=(
            'run:Invoke a spell'
            'list:List available spells'
            'diff:Show changes since last activation'
            'doctor:Check for common issues'
            'create:Create a new manifest'
            'init:Print shell integration'
            'clean:Remove wrapper(s)'
            'completion:Print shell completion script'
            'version:Show version'
            'help:Show help or spell help'
        )
        if (( CURRENT == 2 )); then
            _describe 'spells subcommand' subs
            return
        fi
        if [[ "${words[2]}" == "help" || "${words[2]}" == "clean" ]] && (( CURRENT == 3 )); then
            local -a names
            names=(${(f)"$(spells list 2>/dev/null | awk '{print $1}')"})
            _describe 'spell' names
        fi
    }
    compdef _spells spells

    """

    private static let bashScript = """
    # spellbook bash completion
    # source this file or drop it into /etc/bash_completion.d/.
    _spells_completion() {
        local cur prev
        COMPREPLY=()
        cur="${COMP_WORDS[COMP_CWORD]}"
        prev="${COMP_WORDS[COMP_CWORD-1]}"
        local subs="run list diff doctor create init clean completion version help"
        if [ "$COMP_CWORD" -eq 1 ]; then
            COMPREPLY=( $(compgen -W "$subs" -- "$cur") )
            return 0
        fi
        if [ "$prev" = "help" ] || [ "$prev" = "clean" ]; then
            local names
            names=$(spells list 2>/dev/null | awk '{print $1}')
            COMPREPLY=( $(compgen -W "$names" -- "$cur") )
            return 0
        fi
    }
    complete -F _spells_completion spells

    """

    private static let fishScript = """
    # spellbook fish completion
    # place in ~/.config/fish/completions/spells.fish (or evaluate at startup).
    set -l spells_subs run list diff doctor create init clean completion version help
    complete -c spells -n "__fish_use_subcommand" -a "$spells_subs"
    complete -c spells -n "__fish_seen_subcommand_from help clean" \
        -a "(spells list 2>/dev/null | awk '{print \\$1}')"

    """
}
