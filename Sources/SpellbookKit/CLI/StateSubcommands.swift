import Foundation

enum StateSubcommands {
    struct Context {
        let resolver: ActivationResolver
        let stateStore: StateStore
        let cwd: String
        let onError: (Error) -> Never
        let cacheWriter: ManifestCacheWriterAdapter?

        init(
            resolver: ActivationResolver,
            stateStore: StateStore,
            cwd: String,
            onError: @escaping (Error) -> Never,
            cacheWriter: ManifestCacheWriterAdapter? = nil
        ) {
            self.resolver = resolver
            self.stateStore = stateStore
            self.cwd = cwd
            self.onError = onError
            self.cacheWriter = cacheWriter
        }
    }

    static func runDoctor(
        arguments: [String],
        context: Context,
        binDir: String
    ) -> Never {
        let activation = ActivationCommand(
            resolver: context.resolver,
            wrapperGenerator: WrapperGenerator(writer: AtomicWrapperWriter(), binDirectory: binDir),
            stateStore: context.stateStore,
            manifestContent: FoundationManifestContentReader(),
            cacheWriter: context.cacheWriter
        )
        let command = DoctorCommand(
            resolver: context.resolver,
            stateStore: context.stateStore,
            pathEnv: ProcessInfo.processInfo.environment["PATH"],
            spellbookBinDir: binDir,
            activationCommand: activation,
            cacheWriter: context.cacheWriter,
            wrapperFileSystem: FoundationFileSystem()
        )
        let output = command.run(cwd: context.cwd, fix: arguments.contains("--fix"))
        for line in output.lines { print(line) }
        exit(output.exitCode)
    }

    static func runDiff(context: Context) {
        let command = DiffCommand(
            resolver: context.resolver,
            stateStore: context.stateStore,
            cacheWriter: context.cacheWriter
        )
        do {
            for line in try command.run(cwd: context.cwd) { print(line) }
        } catch { context.onError(error) }
    }

    static func runClean(
        arguments: [String],
        context: Context,
        wrapperWriter: WrapperWriter
    ) {
        let command = CleanCommand(
            resolver: context.resolver,
            stateStore: context.stateStore,
            wrapperWriter: wrapperWriter,
            cacheWriter: context.cacheWriter
        )
        do {
            for line in try command.run(arguments: arguments, cwd: context.cwd) { print(line) }
        } catch { context.onError(error) }
    }
}
