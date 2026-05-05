enum CompletionWalker {
    static func walkSpell(
        _ spell: SpellDefinition,
        request: CompletionRequest,
        offset: Int
    ) -> [CompletionCandidate] {
        if let switchDef = spell.switchBranches {
            return walkSwitch(switchDef, request: request, offset: offset)
        }
        return walkLeaf(spell, request: request, offset: offset)
    }

    private static func walkSwitch(
        _ switchDef: SwitchDefinition,
        request: CompletionRequest,
        offset: Int
    ) -> [CompletionCandidate] {
        if request.isCursor(offset) {
            return switchDef.options.map {
                CompletionCandidate(
                    value: $0.name, kind: .switchOption, description: $0.description
                )
            }
        }
        guard offset < request.tokens.count else { return [] }
        let chosen = request.tokens[offset]
        guard let option = switchDef.options.first(where: {
            $0.name == chosen || $0.aliases.contains(chosen)
        }) else {
            return []
        }
        return walkSpell(option.command, request: request, offset: offset + 1)
    }

    private static func walkLeaf(
        _ spell: SpellDefinition,
        request: CompletionRequest,
        offset: Int
    ) -> [CompletionCandidate] {
        var state = LeafWalkState(spell: spell, offset: offset)
        while state.cursor < request.cword && state.cursor < request.tokens.count {
            let token = request.tokens[state.cursor]
            if !state.consume(token) { return [] }
        }
        if state.cursor != request.cword { return [] }
        return state.candidatesAtCursor(cursorWord: request.cursorWord)
    }
}
