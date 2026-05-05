public struct DoctorCommand {
    private let resolver: ActivationResolver
    private let stateStore: StateStore
    private let pathChecker: PathBinaryChecker?
    private let pathEnv: String?
    private let spellbookBinDir: String
    private let activationCommand: ActivationCommand?
    private let cacheWriter: ManifestCacheWriterAdapter?
    private let wrapperFileSystem: FileSystemProtocol?

    public init(
        resolver: ActivationResolver,
        stateStore: StateStore,
        pathChecker: PathBinaryChecker? = nil,
        pathEnv: String?,
        spellbookBinDir: String,
        activationCommand: ActivationCommand? = nil,
        cacheWriter: ManifestCacheWriterAdapter? = nil,
        wrapperFileSystem: FileSystemProtocol? = nil
    ) {
        self.resolver = resolver
        self.stateStore = stateStore
        self.pathChecker = pathChecker
        self.pathEnv = pathEnv
        self.spellbookBinDir = spellbookBinDir
        self.activationCommand = activationCommand
        self.cacheWriter = cacheWriter
        self.wrapperFileSystem = wrapperFileSystem
    }

    public func run(cwd: String, fix: Bool = false) -> DoctorOutput {
        let report = diagnose(cwd: cwd)
        if let result = try? resolver.resolve(cwd: cwd) {
            ManifestCacheHook.writeIfPossible(writer: cacheWriter, result: result)
        }
        guard fix, let activation = activationCommand else {
            return DoctorOutput(report: report)
        }
        return applyFix(report: report, cwd: cwd, activation: activation)
    }

    private func diagnose(cwd: String) -> DoctorReport {
        let activation = resolveActivation(cwd: cwd)
        let state = readState()
        let input = DoctorInput(
            activationResult: activation.result,
            activationError: activation.error,
            pathEnv: pathEnv,
            spellbookBinDir: spellbookBinDir,
            stateSnapshot: state.snapshot,
            stateError: state.error,
            pathChecker: pathChecker,
            wrapperFileSystem: wrapperFileSystem
        )
        return DoctorResolver().diagnose(input)
    }

    private func resolveActivation(cwd: String) -> (result: ActivationResult?, error: SpellbookError?) {
        do {
            return (try resolver.resolve(cwd: cwd), nil)
        } catch let error as SpellbookError {
            return (nil, error)
        } catch {
            return (nil, nil)
        }
    }

    private func readState() -> (snapshot: StateSnapshot?, error: SpellbookError?) {
        do {
            return (try stateStore.read(), nil)
        } catch let error as SpellbookError {
            return (nil, error)
        } catch {
            return (nil, nil)
        }
    }

    private func applyFix(
        report: DoctorReport,
        cwd: String,
        activation: ActivationCommand
    ) -> DoctorOutput {
        let assessment = DoctorFixer.assess(report: report)
        guard assessment.shouldReactivate else {
            return DoctorOutput(report: report, fixNotes: ["Nothing to fix automatically."])
        }
        do {
            let summary = try activation.activate(cwd: cwd)
            let notes = assessment.reasons.map { "Fixed: \($0)" } +
                ["Re-activated \(summary.spellCount) spells, \(summary.wrapperCount) wrappers."]
            return DoctorOutput(report: diagnose(cwd: cwd), fixNotes: notes)
        } catch {
            return DoctorOutput(report: report, fixNotes: ["Fix failed: \(error)"])
        }
    }
}
