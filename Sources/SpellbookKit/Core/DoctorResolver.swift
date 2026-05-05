public struct DoctorResolver {
    public init() {}

    public func diagnose(_ input: DoctorInput) -> DoctorReport {
        var items: [DiagnosticItem] = []
        items.append(contentsOf: manifestChecks(result: input.activationResult, error: input.activationError))
        if let result = input.activationResult {
            items.append(contentsOf: extendsChecks(result: result))
        }
        items.append(contentsOf: pathChecks(pathEnv: input.pathEnv, binDir: input.spellbookBinDir))
        items.append(contentsOf: stateChecks(error: input.stateError))
        if let result = input.activationResult {
            items.append(contentsOf: wrapperStateChecks(
                manifest: result.manifest,
                manifestPath: result.location.path,
                stateSnapshot: input.stateSnapshot,
                fileSystem: input.wrapperFileSystem
            ))
            items.append(contentsOf: DoctorSemanticChecks.warnings(
                manifest: result.manifest,
                pathChecker: input.pathChecker
            ))
        }
        return DoctorReport(items: items)
    }

    // MARK: - Manifest checks

    private func manifestChecks(
        result: ActivationResult?,
        error: SpellbookError?
    ) -> [DiagnosticItem] {
        guard let result else {
            let message = error.map { "\($0)" } ?? "No manifest found"
            return [DiagnosticItem(severity: .error, category: .manifest, message: "Manifest: \(message)")]
        }
        var items = [DiagnosticItem(
            severity: .info, category: .manifest,
            message: "Manifest: \(result.location.path) (\(result.manifest.spells.count) spells)"
        )]
        if result.location.shadowsHidden {
            items.append(DiagnosticItem(
                severity: .warning, category: .manifest,
                message: "Both spells.yaml and .spells.yaml exist; spells.yaml takes precedence"
            ))
        }
        return items
    }

    // MARK: - Extends checks

    private func extendsChecks(result: ActivationResult) -> [DiagnosticItem] {
        guard result.chain.count > 1 else { return [] }
        return [DiagnosticItem(
            severity: .info, category: .extends,
            message: "Extends chain: " + result.chain.joined(separator: " → ")
        )]
    }

    // MARK: - PATH checks

    private func pathChecks(pathEnv: String?, binDir: String) -> [DiagnosticItem] {
        guard let pathEnv else {
            return [DiagnosticItem(severity: .error, category: .path, message: "PATH environment variable not set")]
        }
        let components = pathEnv.split(separator: ":").map(String.init)
        if components.contains(binDir) {
            return [DiagnosticItem(severity: .info, category: .path, message: "PATH: \(binDir) is in PATH")]
        }
        return [DiagnosticItem(
            severity: .error, category: .path,
            message: "PATH: \(binDir) is not in PATH. Run `spells init <shell>` for setup instructions"
        )]
    }

    // MARK: - State checks

    private func stateChecks(error: SpellbookError?) -> [DiagnosticItem] {
        guard let error else { return [] }
        return [DiagnosticItem(
            severity: .error, category: .wrappers,
            message: "State: \(stateMessage(for: error))"
        )]
    }

    private func stateMessage(for error: SpellbookError) -> String {
        switch error {
        case .unsupportedStateVersion(let found, let supported):
            return "unsupported state version \(found) (expected \(supported))"
                + " — delete state.json and re-activate"
        default:
            return "\(error)"
        }
    }

    // MARK: - Wrapper state checks

    private func wrapperStateChecks(
        manifest: SpellbookManifest,
        manifestPath: String,
        stateSnapshot: StateSnapshot?,
        fileSystem: FileSystemProtocol?
    ) -> [DiagnosticItem] {
        guard let snapshot = stateSnapshot else {
            return [DiagnosticItem(
                severity: .info, category: .wrappers,
                message: "No state file found. Run `spells` to activate"
            )]
        }
        let projectKey = parentDirectory(of: manifestPath)
        guard let project = snapshot.projects[projectKey] else {
            return [DiagnosticItem(
                severity: .warning, category: .wrappers,
                message: "Project not yet activated. Run `spells` to activate"
            )]
        }
        return compareSpellState(manifest: manifest, project: project, fileSystem: fileSystem)
    }

    private func compareSpellState(
        manifest: SpellbookManifest,
        project: ProjectState,
        fileSystem: FileSystemProtocol?
    ) -> [DiagnosticItem] {
        let currentNames = Set(manifest.spells.map(\.name))
        let stateNames = Set(project.spells.keys)
        let added = currentNames.subtracting(stateNames)
        let removed = stateNames.subtracting(currentNames)
        let missing = missingWrappers(project: project, fileSystem: fileSystem)
        var items: [DiagnosticItem] = []
        if !added.isEmpty {
            items.append(DiagnosticItem(
                severity: .warning, category: .wrappers,
                message: "New spells not yet activated: \(added.sorted().joined(separator: ", "))"
            ))
        }
        if !removed.isEmpty {
            items.append(DiagnosticItem(
                severity: .warning, category: .wrappers,
                message: "Stale wrappers for removed spells: \(describeRemoved(removed, project: project))"
            ))
        }
        if !missing.isEmpty {
            items.append(DiagnosticItem(
                severity: .warning, category: .wrappers,
                message: "Missing wrappers: \(missing.sorted().joined(separator: ", ")) — rerun `spells`"
            ))
        }
        if added.isEmpty && removed.isEmpty && missing.isEmpty {
            items.append(DiagnosticItem(severity: .info, category: .wrappers, message: "Wrappers: up to date"))
        }
        return items
    }

    private func missingWrappers(
        project: ProjectState,
        fileSystem: FileSystemProtocol?
    ) -> [String] {
        guard let fileSystem else { return [] }
        return project.spells.compactMap { name, state -> String? in
            guard !state.wrapper.isEmpty else { return nil }
            return fileSystem.probe(state.wrapper) == .present ? nil : name
        }
    }

    private func describeRemoved(_ names: Set<String>, project: ProjectState) -> String {
        names.sorted().map { name in
            if let origin = project.spells[name]?.origin, !origin.isEmpty {
                return "\(name) (was \(origin))"
            }
            return name
        }.joined(separator: ", ")
    }

    private func parentDirectory(of path: String) -> String {
        if path.isEmpty { return path }
        let trimmed = path.hasSuffix("/") ? String(path.dropLast()) : path
        guard let slash = trimmed.lastIndex(of: "/") else { return trimmed }
        if slash == trimmed.startIndex { return "/" }
        return String(trimmed[trimmed.startIndex..<slash])
    }
}
