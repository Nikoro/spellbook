public enum WrapperCompletionResolver {
    public static func resolveCompletion(
        tokens: [String],
        cword: Int,
        manifest: SpellbookManifest,
        wrapper: String
    ) -> [CompletionCandidate] {
        guard let root = manifest.spells.first(where: { $0.name == wrapper }) else {
            return []
        }
        if cword == 0 {
            return resolveNoSpaceTab(root: root)
        }
        let request = CompletionRequest(tokens: tokens, cword: cword, wrapper: wrapper)
        return CompletionWalker.walkSpell(root, request: request, offset: 1)
    }

    private static func resolveNoSpaceTab(
        root: SpellDefinition
    ) -> [CompletionCandidate] {
        let probeRequest = CompletionRequest(
            tokens: [root.name, ""], cword: 1, wrapper: root.name
        )
        let candidates = CompletionWalker.walkSpell(root, request: probeRequest, offset: 1)
        if candidates.contains(where: { $0.kind == .runAsIs }) {
            return [.endOfGrammarFallThrough]
        }
        return candidates
    }
}
