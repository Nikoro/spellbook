public protocol StateStore {
    func read() throws -> StateSnapshot?
    func write(_ snapshot: StateSnapshot) throws
}
