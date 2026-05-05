@testable import SpellbookKit

public final class MockStateStore: StateStore {
    public var stored: StateSnapshot?
    public var readError: Error?
    public var writeError: Error?

    public init() {}

    public func read() throws -> StateSnapshot? {
        if let error = readError { throw error }
        return stored
    }

    public func write(_ snapshot: StateSnapshot) throws {
        if let error = writeError { throw error }
        stored = snapshot
    }
}
