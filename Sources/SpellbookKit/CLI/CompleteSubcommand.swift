enum CompleteSubcommand {
    struct Context {
        let resolver: ActivationResolver
        let cacheReader: ManifestCacheReaderAdapter
        let cacheWriter: ManifestCacheWriterAdapter
        let cwd: String
    }

    static func run(arguments: [String], context: Context) {
        let command = CompleteCommand(
            resolver: context.resolver,
            cacheReader: context.cacheReader,
            cacheWriter: context.cacheWriter
        )
        for line in command.run(arguments: arguments, cwd: context.cwd) {
            print(line)
        }
    }
}
