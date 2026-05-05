@testable import SpellbookKit

public final class MockPathBinaryChecker: PathBinaryChecker {
    public let binaries: Set<String>

    public init(binaries: Set<String>) {
        self.binaries = binaries
    }

    public func isInPath(_ name: String) -> Bool {
        binaries.contains(name)
    }
}
