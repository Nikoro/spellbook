public struct StateSnapshot: Codable, Equatable, Sendable {
    public static let currentVersion = 1

    public let version: Int
    public let updatedAt: String
    public let projects: [String: ProjectState]

    public init(
        version: Int = StateSnapshot.currentVersion,
        updatedAt: String,
        projects: [String: ProjectState] = [:]
    ) {
        self.version = version
        self.updatedAt = updatedAt
        self.projects = projects
    }

    enum CodingKeys: String, CodingKey {
        case version
        case updatedAt = "updated_at"
        case projects
    }
}
