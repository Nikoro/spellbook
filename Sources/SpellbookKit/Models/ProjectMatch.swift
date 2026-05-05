public struct ProjectMatch: Equatable, Sendable {
    public let projectPath: String
    public let originManifest: String

    public init(projectPath: String, originManifest: String) {
        self.projectPath = projectPath
        self.originManifest = originManifest
    }
}
