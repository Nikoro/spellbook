public struct PreparedSpell: Equatable, Sendable {
    public let name: String
    public let resolvedScript: String
    public let shell: String?
    public let resolvedWorkingDir: String
    public let silent: Bool
    public let manifestPath: String
    public let environment: [String: String]

    public init(
        name: String,
        resolvedScript: String,
        shell: String? = nil,
        resolvedWorkingDir: String,
        silent: Bool = false,
        manifestPath: String,
        environment: [String: String] = [:]
    ) {
        self.name = name
        self.resolvedScript = resolvedScript
        self.shell = shell
        self.resolvedWorkingDir = resolvedWorkingDir
        self.silent = silent
        self.manifestPath = manifestPath
        self.environment = environment
    }
}
