@testable import SpellbookKit

public final class RecordingFileLock: FileLock {
    public private(set) var acquireCount = 0
    public private(set) var releaseCount = 0

    public init() {}

    public func withExclusiveLock<T>(_ body: () throws -> T) throws -> T {
        acquireCount += 1
        defer { releaseCount += 1 }
        return try body()
    }
}
