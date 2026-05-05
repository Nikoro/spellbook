public struct ActivationResolver {
    private let fileSystem: FileSystemProtocol
    private let manifestReader: ManifestReader
    private let manifestLoader: ManifestLoader
    private let pathChecker: PathBinaryChecker?
    private let home: String?

    public init(
        fileSystem: FileSystemProtocol,
        manifestReader: ManifestReader,
        manifestLoader: ManifestLoader,
        pathChecker: PathBinaryChecker? = nil,
        home: String? = nil
    ) {
        self.fileSystem = fileSystem
        self.manifestReader = manifestReader
        self.manifestLoader = manifestLoader
        self.pathChecker = pathChecker
        self.home = home
    }

    public func resolve(cwd: String) throws -> ActivationResult {
        let location = try discoverManifest(cwd: cwd)
        let resolution = try loadAndMerge(at: location.path)
        try validate(resolution.manifest)
        return ActivationResult(
            manifest: resolution.manifest,
            location: location,
            chain: resolution.chain,
            spellOrigins: resolution.spellOrigins
        )
    }

    private func discoverManifest(cwd: String) throws -> ManifestLocation {
        let walker = DirectoryWalker(fileSystem: fileSystem, home: home)
        guard let location = try walker.findManifest(startingAt: cwd) else {
            throw SpellbookError.noManifestFound
        }
        return location
    }

    private func loadAndMerge(at path: String) throws -> ExtendsResolver.Resolution {
        let manifest = try manifestReader.read(at: path)
        let resolver = ExtendsResolver(loader: manifestLoader)
        return try resolver.resolveWithChain(manifest, basePath: path)
    }

    private func validate(_ manifest: SpellbookManifest) throws {
        let validator = SpellbookValidator(pathChecker: pathChecker)
        let errors = validator.validate(manifest)
        if let first = errors.first { throw first }
    }
}
