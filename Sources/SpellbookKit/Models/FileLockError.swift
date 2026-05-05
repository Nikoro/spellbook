public enum FileLockError: Error, Equatable, Sendable {
    case openFailed(path: String, errno: Int32)
    case lockFailed(path: String, errno: Int32)
}
