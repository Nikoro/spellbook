public struct RunResolver {
    private let fileSystem: FileSystemProtocol
    private let manifestReader: ManifestReader
    private let manifestLoader: ManifestLoader
    private let pathChecker: PathBinaryChecker?
    private let overrideLookup: OverrideLookup?
    private let choiceProvider: FiniteChoiceProvider?
    private let home: String?

    public init(
        fileSystem: FileSystemProtocol,
        manifestReader: ManifestReader,
        manifestLoader: ManifestLoader,
        pathChecker: PathBinaryChecker? = nil,
        overrideLookup: OverrideLookup? = nil,
        choiceProvider: FiniteChoiceProvider? = nil,
        home: String? = nil
    ) {
        self.fileSystem = fileSystem
        self.manifestReader = manifestReader
        self.manifestLoader = manifestLoader
        self.pathChecker = pathChecker
        self.overrideLookup = overrideLookup
        self.choiceProvider = choiceProvider
        self.home = home
    }

    public func resolve(
        spellName: String,
        argv: [String],
        cwd: String
    ) throws -> PreparedSpell {
        let location = try discoverManifest(cwd: cwd)
        let merged = try loadAndMerge(at: location.path)
        try validate(merged)
        let spell = try findSpell(named: spellName, in: merged)
        return try resolveSpell(
            spell, argv: argv, manifestPath: location.path, cwd: cwd
        )
    }

    private func discoverManifest(cwd: String) throws -> ManifestLocation {
        let walker = DirectoryWalker(fileSystem: fileSystem, home: home)
        guard let location = try walker.findManifest(startingAt: cwd) else {
            throw SpellbookError.noManifestFound
        }
        return location
    }

    private func loadAndMerge(at path: String) throws -> SpellbookManifest {
        let manifest = try manifestReader.read(at: path)
        let resolver = ExtendsResolver(loader: manifestLoader)
        return try resolver.resolve(manifest, basePath: path)
    }

    private func validate(_ manifest: SpellbookManifest) throws {
        let validator = SpellbookValidator(pathChecker: pathChecker)
        let errors = validator.validate(manifest)
        if let first = errors.first { throw first }
    }

    private func findSpell(
        named name: String,
        in manifest: SpellbookManifest
    ) throws -> SpellDefinition {
        guard let spell = SpellLookup().find(name: name, in: manifest) else {
            throw SpellbookError.spellNotFound(name: name)
        }
        return spell
    }

    private func resolveSpell(
        _ spell: SpellDefinition,
        argv: [String],
        manifestPath: String,
        cwd: String
    ) throws -> PreparedSpell {
        let nav = try SwitchNavigator(choiceProvider: choiceProvider).resolve(
            spell: spell, argv: argv, spellName: spell.name
        )
        let terminal = nav.terminal
        let resolvedScript = try resolveScript(
            spell: spell, terminal: terminal, argv: nav.remainingArgv
        )
        let manifestDir = parentDirectory(of: manifestPath)
        let resolvedCwd = WorkingDirectoryResolver().resolve(
            workingDir: terminal.workingDir ?? spell.workingDir,
            originManifestDir: manifestDir,
            invocationCwd: cwd, home: home
        )
        let env = EnvironmentBuilder().build(.init(
            spellName: spell.name, projectRoot: manifestDir,
            manifestPath: manifestPath, originPath: manifestPath,
            workingDir: resolvedCwd
        ))
        return PreparedSpell(
            name: spell.name, resolvedScript: resolvedScript,
            shell: terminal.shell ?? spell.shell,
            resolvedWorkingDir: resolvedCwd,
            silent: terminal.silent || spell.silent,
            manifestPath: manifestPath, environment: env
        )
    }

    private func resolveScript(
        spell: SpellDefinition,
        terminal: SpellDefinition,
        argv: [String]
    ) throws -> String {
        let script = terminal.script ?? ""
        let hasPassthrough = script.contains("...args")
        let arguments = try ParamResolver(choiceProvider: choiceProvider).resolve(
            argv: argv, params: terminal.params,
            spell: spell.name, passthrough: hasPassthrough
        )
        let composite = compositeSpell(spell: spell, terminal: terminal)
        return PlaceholderResolver().resolve(
            script: script, spell: composite,
            arguments: arguments, overrideLookup: overrideLookup
        )
    }

    private func parentDirectory(of path: String) -> String {
        if path.isEmpty { return path }
        let trimmed = path.hasSuffix("/") ? String(path.dropLast()) : path
        guard let slash = trimmed.lastIndex(of: "/") else { return trimmed }
        if slash == trimmed.startIndex { return "/" }
        return String(trimmed[trimmed.startIndex..<slash])
    }

    private func compositeSpell(
        spell: SpellDefinition,
        terminal: SpellDefinition
    ) -> SpellDefinition {
        SpellDefinition(
            identity: spell.identity,
            body: terminal.body,
            runtime: SpellRuntime(
                override: spell.override,
                silent: terminal.silent || spell.silent,
                workingDir: terminal.workingDir ?? spell.workingDir,
                shell: terminal.shell ?? spell.shell
            )
        )
    }
}
