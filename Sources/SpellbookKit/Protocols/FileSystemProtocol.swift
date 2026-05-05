public protocol FileSystemProtocol {
    func probe(_ path: String) -> FileProbe
}
