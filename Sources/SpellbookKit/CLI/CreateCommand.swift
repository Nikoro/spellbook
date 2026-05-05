public struct CreateCommand {
    private let fileSystem: FileSystemProtocol
    private let fileWriter: FileWriter

    public init(fileSystem: FileSystemProtocol, fileWriter: FileWriter) {
        self.fileSystem = fileSystem
        self.fileWriter = fileWriter
    }

    public func run(cwd: String, spellName: String? = nil) throws -> String {
        let targetPath = CreateResolver.targetPath(cwd: cwd)
        let hiddenPath = hiddenTargetPath(cwd: cwd)
        if fileSystem.probe(targetPath) == .present || fileSystem.probe(hiddenPath) == .present {
            let existing = fileSystem.probe(targetPath) == .present ? targetPath : hiddenPath
            throw SpellbookError.manifestAlreadyExists(path: existing)
        }
        let content = try CreateResolver.manifestContent(spellName: spellName)
        try fileWriter.writeFile(content: content, to: targetPath)
        return targetPath
    }

    private func hiddenTargetPath(cwd: String) -> String {
        if cwd.hasSuffix("/") { return cwd + ".spells.yaml" }
        return cwd + "/.spells.yaml"
    }
}
