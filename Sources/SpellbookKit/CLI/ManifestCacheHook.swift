public enum ManifestCacheHook {
    public static func writeIfPossible(
        writer: ManifestCacheWriterAdapter?,
        result: ActivationResult
    ) {
        guard let writer = writer else { return }
        let extendsChain = [result.location.path] + result.chain
        writer.writeIfPossible(
            merged: result.manifest,
            extendsChain: extendsChain,
            projectRootManifestPath: result.location.path
        )
    }
}
