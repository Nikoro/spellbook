import Foundation

public struct FoundationPathBinaryChecker: PathBinaryChecker {
    private let pathDirectories: [String]
    private let spellbookBin: String
    private let fileManager: FileManager

    public init(
        pathEnv: String,
        spellbookBin: String,
        fileManager: FileManager = .default
    ) {
        let parts = pathEnv.split(separator: ":").map(String.init)
        self.pathDirectories = parts.map { $0.hasSuffix("/") ? String($0.dropLast()) : $0 }
        self.spellbookBin = spellbookBin.hasSuffix("/")
            ? String(spellbookBin.dropLast())
            : spellbookBin
        self.fileManager = fileManager
    }

    public func isInPath(_ name: String) -> Bool {
        for directory in pathDirectories where directory != spellbookBin {
            let candidate = directory + "/" + name
            if fileManager.isExecutableFile(atPath: candidate) { return true }
        }
        return false
    }
}
