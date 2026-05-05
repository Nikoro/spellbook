public struct DirectoryWalker {
    private static let maxIterations = 60
    private static let visibleName = "spells.yaml"
    private static let hiddenName = ".spells.yaml"

    private let fileSystem: FileSystemProtocol
    private let home: String?

    public init(fileSystem: FileSystemProtocol, home: String?) {
        self.fileSystem = fileSystem
        self.home = home
    }

    public func findManifest(startingAt cwd: String) throws -> ManifestLocation? {
        var directory = cwd
        var iterations = 0
        while iterations <= Self.maxIterations {
            switch probeDirectory(directory) {
            case .found(let location):
                return location
            case .denied:
                return homeFallback()
            case .empty:
                break
            }
            let parent = parentDirectory(of: directory)
            if parent == directory { break }
            directory = parent
            iterations += 1
        }
        if iterations > Self.maxIterations {
            throw SpellbookError.walkUpTooDeep(path: cwd)
        }
        return homeFallback()
    }

    private enum DirectoryProbe {
        case found(ManifestLocation)
        case denied
        case empty
    }

    private func probeDirectory(_ directory: String) -> DirectoryProbe {
        let visible = join(directory, Self.visibleName)
        let hidden = join(directory, Self.hiddenName)
        let visibleProbe = fileSystem.probe(visible)
        let hiddenProbe = fileSystem.probe(hidden)
        if visibleProbe == .denied || hiddenProbe == .denied { return .denied }
        let hasVisible = visibleProbe == .present
        let hasHidden = hiddenProbe == .present
        if hasVisible {
            return .found(ManifestLocation(path: visible, source: .project, shadowsHidden: hasHidden))
        }
        if hasHidden {
            return .found(ManifestLocation(path: hidden, source: .project))
        }
        return .empty
    }

    private func homeFallback() -> ManifestLocation? {
        guard let home = home else { return nil }
        let path = join(home, Self.visibleName)
        if fileSystem.probe(path) == .present {
            return ManifestLocation(path: path, source: .homeFallback)
        }
        return nil
    }

    private func parentDirectory(of path: String) -> String {
        if path == "/" || path.isEmpty { return path }
        let trimmed = path.hasSuffix("/") ? String(path.dropLast()) : path
        guard let slash = trimmed.lastIndex(of: "/") else { return trimmed }
        if slash == trimmed.startIndex { return "/" }
        return String(trimmed[trimmed.startIndex..<slash])
    }

    private func join(_ directory: String, _ name: String) -> String {
        if directory.hasSuffix("/") { return directory + name }
        return directory + "/" + name
    }
}
