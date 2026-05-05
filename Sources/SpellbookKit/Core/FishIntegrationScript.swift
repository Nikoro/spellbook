enum FishIntegrationScript {
    static let content = #"""
# Spellbook integration v1 (fish)
# Source this file from ~/.config/fish/config.fish.

if test -z "$SPELLBOOK_HOME"
    set -gx SPELLBOOK_HOME "$HOME/.spellbook"
end
if not contains "$SPELLBOOK_HOME/bin" $PATH
    set -gx PATH "$SPELLBOOK_HOME/bin" $PATH
end

function __spells_tab_complete
    set -l head (commandline -cp)
    set -l tail (commandline -c)
    set -l tokens (commandline -opc)
    set -l cur (commandline -ct)
    if test (count $tokens) -eq 0
        commandline -f complete
        return
    end
    set -l wrapper $tokens[1]
    if test -z "$SPELLBOOK_HOME"; or not test -x "$SPELLBOOK_HOME/bin/$wrapper"
        commandline -f complete
        return
    end
    set -l words $tokens $cur
    set -l cword (math (count $words) - 1)
    set -l raw (spells complete $wrapper --cword $cword -- $words)
    if test (count $raw) -gt 0; and test $raw[1] = '__SPELLBOOK_FALLTHROUGH__'
        commandline -f complete
        return
    end
    set -l candidates
    for line in $raw
        test -z "$line"; and continue
        set candidates $candidates (string split \t -- $line)[1]
    end
    set -l count (count $candidates)
    if test $count -eq 0
        return
    end
    set -l selection
    if test $count -eq 1
        set selection $candidates[1]
    else
        set selection (printf '%s\n' $candidates | spells pick)
        test -z "$selection"; and return
    end
    commandline -rt -- "$selection"
end

bind \t __spells_tab_complete 2>/dev/null
"""#
}
