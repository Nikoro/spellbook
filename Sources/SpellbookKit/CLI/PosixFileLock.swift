import Foundation
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

public struct PosixFileLock: FileLock {
    private let path: String
    private let fileManager: FileManager

    public init(path: String, fileManager: FileManager = .default) {
        self.path = path
        self.fileManager = fileManager
    }

    public func withExclusiveLock<T>(_ body: () throws -> T) throws -> T {
        try ensureParentDirectoryExists()
        let descriptor = open(path, O_RDWR | O_CREAT | O_CLOEXEC, 0o600)
        guard descriptor >= 0 else {
            throw FileLockError.openFailed(path: path, errno: errno)
        }
        defer { close(descriptor) }
        guard flock(descriptor, LOCK_EX) == 0 else {
            throw FileLockError.lockFailed(path: path, errno: errno)
        }
        defer { _ = flock(descriptor, LOCK_UN) }
        return try body()
    }

    private func ensureParentDirectoryExists() throws {
        let directory = (path as NSString).deletingLastPathComponent
        guard !directory.isEmpty else { return }
        try fileManager.createDirectory(
            atPath: directory, withIntermediateDirectories: true
        )
    }
}
