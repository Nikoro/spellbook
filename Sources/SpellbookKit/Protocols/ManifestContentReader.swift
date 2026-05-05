public protocol ManifestContentReader {
    func readContent(at path: String) throws -> String
}
