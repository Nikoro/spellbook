@testable import SpellbookKit

public final class MockFileWriter: FileWriter {
    public var writtenFiles: [String: String] = [:]
    public var errorToThrow: Error?

    public init() {}

    public func writeFile(content: String, to path: String) throws {
        if let error = errorToThrow { throw error }
        writtenFiles[path] = content
    }
}
