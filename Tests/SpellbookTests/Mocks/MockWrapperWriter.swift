@testable import SpellbookKit

public final class MockWrapperWriter: WrapperWriter {
    public var writtenFiles: [String: String] = [:]
    public var removedPaths: [String] = []
    public var failAfterCount: Int?
    private var writeCount = 0

    public init() {}

    public func writeWrapper(content: String, to path: String) throws {
        if let limit = failAfterCount, writeCount >= limit {
            throw WrapperWriteError.simulatedFailure
        }
        writtenFiles[path] = content
        writeCount += 1
    }

    public func removeWrapper(at path: String) throws {
        writtenFiles.removeValue(forKey: path)
        removedPaths.append(path)
    }
}
