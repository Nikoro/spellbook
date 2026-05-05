import Foundation

public struct AtomicWrapperWriter: WrapperWriter {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func writeWrapper(content: String, to path: String) throws {
        let directory = (path as NSString).deletingLastPathComponent
        try fileManager.createDirectory(
            atPath: directory, withIntermediateDirectories: true
        )
        let tempPath = path + ".tmp"
        let data = Data(content.utf8)
        try data.write(to: URL(fileURLWithPath: tempPath))
        try fileManager.setAttributes(
            [.posixPermissions: 0o755], ofItemAtPath: tempPath
        )
        if fileManager.fileExists(atPath: path) {
            try fileManager.removeItem(atPath: path)
        }
        try fileManager.moveItem(atPath: tempPath, toPath: path)
    }

    public func removeWrapper(at path: String) throws {
        guard fileManager.fileExists(atPath: path) else { return }
        try fileManager.removeItem(atPath: path)
    }
}
