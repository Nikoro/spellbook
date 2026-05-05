import Foundation

public struct FoundationManifestContentReader: ManifestContentReader {
    public init() {}

    public func readContent(at path: String) throws -> String {
        try String(contentsOfFile: path, encoding: .utf8)
    }
}
