public struct OverrideResolver: OverrideLookup {
    private let pathDirectories: [String]
    private let spellbookBin: String
    private let fileSystem: FileSystemProtocol

    public init(
        pathDirectories: [String],
        spellbookBin: String,
        fileSystem: FileSystemProtocol
    ) {
        self.pathDirectories = pathDirectories
        self.spellbookBin = spellbookBin
        self.fileSystem = fileSystem
    }

    public func externalCommand(for spellName: String) -> String? {
        for directory in pathDirectories {
            let normalized = directory.hasSuffix("/")
                ? String(directory.dropLast())
                : directory
            guard normalized != spellbookBin else { continue }

            let candidate = normalized + "/" + spellName
            if fileSystem.probe(candidate) == .present {
                return candidate
            }
        }
        return nil
    }
}
