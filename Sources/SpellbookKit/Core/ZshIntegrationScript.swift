enum ZshIntegrationScript {
    static let content = #"""
# Spellbook integration v1 (zsh)
# Source this file from ~/.zshrc. `spells init zsh` emits it again on demand.

export SPELLBOOK_HOME="${SPELLBOOK_HOME:-$HOME/.spellbook}"
case ":$PATH:" in
    *":$SPELLBOOK_HOME/bin:"*) ;;
    *) export PATH="$SPELLBOOK_HOME/bin:$PATH" ;;
esac

# Spellbook custom completion. The widget defers the picker to the main
# shell loop (via `zle accept-line` + precmd) so zle does not fight for
# keyboard input while the picker owns /dev/tty.
typeset -g _SPELLBOOK_PENDING_BUFFER=""
typeset -g _SPELLBOOK_PENDING_CANDIDATES=""
typeset -g _SPELLBOOK_PENDING_REPLACE=""

_spells_zle_complete() {
    local buf="$LBUFFER"
    local -a toks
    toks=(${(z)buf})
    if (( ${#toks[@]} == 0 )); then
        zle expand-or-complete
        return
    fi
    local wrapper="${toks[1]}"
    if [[ -z "$SPELLBOOK_HOME" || ! -x "$SPELLBOOK_HOME/bin/$wrapper" ]]; then
        zle expand-or-complete
        return
    fi
    local -a words
    words=("${toks[@]}")
    if [[ "$buf" == *" " ]]; then
        words+=("")
    fi
    local cword=$(( ${#words[@]} - 1 ))
    local -a lines
    lines=("${(@f)$(spells complete "$wrapper" --cword "$cword" -- "${words[@]}")}")
    if [[ "${lines[1]}" == "__SPELLBOOK_FALLTHROUGH__" ]]; then
        zle expand-or-complete
        return
    fi
    local -a candidates
    local line
    for line in "${lines[@]}"; do
        [[ -z "$line" ]] && continue
        candidates+=("${line%%$'\t'*}")
    done
    if (( ${#candidates[@]} == 0 )); then
        return
    fi
    if (( ${#candidates[@]} == 1 )); then
        local current="${words[-1]}"
        if [[ -n "$current" ]]; then
            LBUFFER="${LBUFFER%$current}${candidates[1]}"
        elif [[ "$buf" == *" " ]]; then
            LBUFFER="$LBUFFER${candidates[1]}"
        else
            LBUFFER="$LBUFFER ${candidates[1]}"
        fi
        return
    fi
    # Multi-candidate: stash context, commit an empty line so zle releases
    # the terminal, then resume in precmd with the picker.
    _SPELLBOOK_PENDING_BUFFER="$buf"
    _SPELLBOOK_PENDING_CANDIDATES="${(F)candidates}"
    _SPELLBOOK_PENDING_REPLACE="${words[-1]}"
    BUFFER=""
    zle accept-line
}

_spells_resume_picker() {
    [[ -z "$_SPELLBOOK_PENDING_CANDIDATES" ]] && return
    local buf="$_SPELLBOOK_PENDING_BUFFER"
    local replace="$_SPELLBOOK_PENDING_REPLACE"
    local cands="$_SPELLBOOK_PENDING_CANDIDATES"
    _SPELLBOOK_PENDING_BUFFER=""
    _SPELLBOOK_PENDING_CANDIDATES=""
    _SPELLBOOK_PENDING_REPLACE=""
    local selection
    selection=$(print -r -- "$cands" | spells pick)
    local new_buf="$buf"
    if [[ -n "$selection" ]]; then
        if [[ -n "$replace" ]]; then
            new_buf="${buf%$replace}$selection"
        elif [[ "$buf" == *" " ]]; then
            new_buf="$buf$selection"
        else
            new_buf="$buf $selection"
        fi
    fi
    print -z -- "$new_buf"
}

_spells_install_widget() {
    zle -N _spells_zle_complete
    bindkey '^I' _spells_zle_complete
    autoload -Uz add-zsh-hook
    add-zsh-hook precmd _spells_resume_picker
}

_spells_install_widget
"""#
}
