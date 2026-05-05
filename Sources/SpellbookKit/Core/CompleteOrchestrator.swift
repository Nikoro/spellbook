public enum CompleteOrchestrator {
    public static func compute(
        args: CompleteCommandArgs,
        manifest: SpellbookManifest
    ) -> [String] {
        let candidates = WrapperCompletionResolver.resolveCompletion(
            tokens: args.tokens,
            cword: args.cword,
            manifest: manifest,
            wrapper: args.wrapper
        )
        let filtered = applyFuzzyFilter(candidates: candidates, args: args)
        return CompletionLineFormatter.format(filtered)
    }

    private static func applyFuzzyFilter(
        candidates: [CompletionCandidate],
        args: CompleteCommandArgs
    ) -> [CompletionCandidate] {
        let cursorWord = args.cword < args.tokens.count ? args.tokens[args.cword] : ""
        if cursorWord.isEmpty || candidates.count <= 1 { return candidates }
        if candidates.contains(where: { $0.kind == .fallthrough }) { return candidates }
        let values = candidates.map(\.value)
        let ranked = FuzzyMatcher.rank(query: cursorWord, candidates: values)
        let byValue = Dictionary(uniqueKeysWithValues: candidates.map { ($0.value, $0) })
        return ranked.compactMap { byValue[$0.candidate] }
    }
}
