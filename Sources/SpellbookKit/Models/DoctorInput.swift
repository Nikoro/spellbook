public struct DoctorInput {
    public let activationResult: ActivationResult?
    public let activationError: SpellbookError?
    public let pathEnv: String?
    public let spellbookBinDir: String
    public let stateSnapshot: StateSnapshot?
    public let stateError: SpellbookError?
    public let pathChecker: PathBinaryChecker?
    public let wrapperFileSystem: FileSystemProtocol?

    public init(
        activationResult: ActivationResult?,
        activationError: SpellbookError?,
        pathEnv: String?,
        spellbookBinDir: String,
        stateSnapshot: StateSnapshot?,
        stateError: SpellbookError? = nil,
        pathChecker: PathBinaryChecker? = nil,
        wrapperFileSystem: FileSystemProtocol? = nil
    ) {
        self.activationResult = activationResult
        self.activationError = activationError
        self.pathEnv = pathEnv
        self.spellbookBinDir = spellbookBinDir
        self.stateSnapshot = stateSnapshot
        self.stateError = stateError
        self.pathChecker = pathChecker
        self.wrapperFileSystem = wrapperFileSystem
    }
}
