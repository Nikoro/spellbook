public protocol FileLock {
    func withExclusiveLock<T>(_ body: () throws -> T) throws -> T
}
