enum ScalarListReader {
    static func read(_ node: YAMLNode) -> [String] {
        if case .sequence(let items) = node {
            return items.compactMap { $0.scalar }
        }
        if case .scalar(let raw) = node {
            return CommaSeparated.split(raw)
        }
        return []
    }
}
