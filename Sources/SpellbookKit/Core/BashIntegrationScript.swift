enum BashIntegrationScript {
    static let content = #"""
# Spellbook integration v1 (bash)
# Source this file from ~/.bashrc. `spells init bash` emits it again on demand.

export SPELLBOOK_HOME="${SPELLBOOK_HOME:-$HOME/.spellbook}"
case ":$PATH:" in
    *":$SPELLBOOK_HOME/bin:"*) ;;
    *) export PATH="$SPELLBOOK_HOME/bin:$PATH" ;;
esac

# Spellbook custom completion. Bound directly to TAB via `bind -x`, which
# runs the handler as a normal foreground command (readline releases the
# terminal), so the picker can own /dev/tty without fighting readline.
_spells_tab_complete() {
    local buf="$READLINE_LINE"
    local head="${buf:0:$READLINE_POINT}"
    local tail="${buf:$READLINE_POINT}"
    # Tokenize the head with shell rules (eval a printf quoting hack).
    local -a toks
    eval "toks=($head)" 2>/dev/null || toks=()
    if [ "${#toks[@]}" -eq 0 ]; then
        return
    fi
    local wrapper="${toks[0]}"
    if [ -z "$SPELLBOOK_HOME" ] || [ ! -x "$SPELLBOOK_HOME/bin/$wrapper" ]; then
        return
    fi
    # If the head ends with a space the cursor is on a new empty token.
    local -a words
    words=("${toks[@]}")
    if [[ "$head" == *" " ]]; then
        words+=("")
    fi
    local cword=$(( ${#words[@]} - 1 ))
    local raw
    raw=$(spells complete "$wrapper" --cword "$cword" -- "${words[@]}")
    if [ "$(printf '%s' "$raw" | head -n 1)" = "__SPELLBOOK_FALLTHROUGH__" ]; then
        # Hand back to default filename completion.
        local cur="${words[-1]}"
        local -a files
        mapfile -t files < <(compgen -f -- "$cur")
        if [ "${#files[@]}" -eq 1 ]; then
            READLINE_LINE="${head%$cur}${files[0]}$tail"
            READLINE_POINT=$(( ${#head} - ${#cur} + ${#files[0]} ))
        fi
        return
    fi
    local -a candidates=()
    local line
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        candidates+=("${line%%$'\t'*}")
    done <<< "$raw"
    local count="${#candidates[@]}"
    if [ "$count" -eq 0 ]; then
        return
    fi
    local selection
    if [ "$count" -eq 1 ]; then
        selection="${candidates[0]}"
    else
        selection=$(printf '%s\n' "${candidates[@]}" | spells pick)
        [ -z "$selection" ] && return
    fi
    local cur="${words[-1]}"
    if [ -n "$cur" ]; then
        READLINE_LINE="${head%$cur}$selection$tail"
        READLINE_POINT=$(( ${#head} - ${#cur} + ${#selection} ))
    elif [[ "$head" == *" " ]]; then
        READLINE_LINE="$head$selection$tail"
        READLINE_POINT=$(( ${#head} + ${#selection} ))
    else
        READLINE_LINE="$head $selection$tail"
        READLINE_POINT=$(( ${#head} + 1 + ${#selection} ))
    fi
}

bind -x '"\t": _spells_tab_complete' 2>/dev/null || true
"""#
}
