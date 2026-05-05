public struct ManifestLocation: Equatable, Sendable {
    public enum Source: Equatable, Sendable {
        case project
        case homeFallback
    }

    public let path: String
    public let source: Source
    public let shadowsHidden: Bool

    public init(path: String, source: Source, shadowsHidden: Bool = false) {
        self.path = path
        self.source = source
        self.shadowsHidden = shadowsHidden
    }
}
