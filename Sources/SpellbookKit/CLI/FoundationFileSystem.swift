import Foundation

public struct FoundationFileSystem: FileSystemProtocol {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func probe(_ path: String) -> FileProbe {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory) else {
            if fileManager.isReadableFile(atPath: (path as NSString).deletingLastPathComponent) {
                return .missing
            }
            return .denied
        }
        return .present
    }
}
