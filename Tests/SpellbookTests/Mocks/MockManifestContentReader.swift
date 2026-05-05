@testable import SpellbookKit

public final class MockManifestContentReader: ManifestContentReader {
    public var contents: [String: String] = [:]

    public init() {}

    public func readContent(at path: String) throws -> String {
        contents[path] ?? ""
    }
}
