import Foundation

public struct StateFile: StateStore {
    private let path: String
    private let fileManager: FileManager

    public init(path: String, fileManager: FileManager = .default) {
        self.path = path
        self.fileManager = fileManager
    }

    public func read() throws -> StateSnapshot? {
        guard fileManager.fileExists(atPath: path) else { return nil }
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let snapshot = try JSONDecoder().decode(StateSnapshot.self, from: data)
        guard snapshot.version == StateSnapshot.currentVersion else {
            throw SpellbookError.unsupportedStateVersion(
                found: snapshot.version, supported: StateSnapshot.currentVersion
            )
        }
        return snapshot
    }

    public func write(_ snapshot: StateSnapshot) throws {
        let directory = (path as NSString).deletingLastPathComponent
        try fileManager.createDirectory(
            atPath: directory, withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(snapshot)
        let tempPath = path + ".tmp"
        try data.write(to: URL(fileURLWithPath: tempPath))
        if fileManager.fileExists(atPath: path) {
            try fileManager.removeItem(atPath: path)
        }
        try fileManager.moveItem(atPath: tempPath, toPath: path)
    }
}
