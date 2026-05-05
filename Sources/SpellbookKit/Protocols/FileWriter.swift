public protocol FileWriter {
    func writeFile(content: String, to path: String) throws
}
