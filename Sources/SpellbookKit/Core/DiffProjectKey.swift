enum DiffProjectKey {
    static func parent(of path: String) -> String {
        if path.isEmpty { return path }
        let trimmed = path.hasSuffix("/") ? String(path.dropLast()) : path
        guard let slash = trimmed.lastIndex(of: "/") else { return trimmed }
        if slash == trimmed.startIndex { return "/" }
        return String(trimmed[trimmed.startIndex..<slash])
    }
}
