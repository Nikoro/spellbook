public protocol WrapperWriter {
    func writeWrapper(content: String, to path: String) throws
    func removeWrapper(at path: String) throws
}
