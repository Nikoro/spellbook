import Foundation

public struct FoundationManifestReader: ManifestReader {
    public init() {}

    public func read(at path: String) throws -> SpellbookManifest {
        let content = try String(contentsOfFile: path, encoding: .utf8)
        let lines = try YAMLTokenizer().tokenize(content)
        let node = try YAMLParser().parse(lines)
        return try SpellbookParser().parse(node)
    }
}
