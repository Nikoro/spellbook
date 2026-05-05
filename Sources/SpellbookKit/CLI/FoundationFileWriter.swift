import Foundation

public struct FoundationFileWriter: FileWriter {
    public init() {}

    public func writeFile(content: String, to path: String) throws {
        try Data(content.utf8).write(to: URL(fileURLWithPath: path))
    }
}
