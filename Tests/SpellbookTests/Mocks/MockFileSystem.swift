@testable import SpellbookKit

public final class MockFileSystem: FileSystemProtocol {
    public var files: Set<String> = []
    public var deniedPaths: Set<String> = []

    public init() {}

    public func probe(_ path: String) -> FileProbe {
        if deniedPaths.contains(path) { return .denied }
        if files.contains(path) { return .present }
        return .missing
    }
}
