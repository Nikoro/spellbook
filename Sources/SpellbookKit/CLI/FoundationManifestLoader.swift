import Foundation

public struct FoundationManifestLoader: ManifestLoader {
    private let fileSystem: FileSystemProtocol
    private let reader: ManifestReader

    public init(
        fileSystem: FileSystemProtocol,
        reader: ManifestReader = FoundationManifestReader()
    ) {
        self.fileSystem = fileSystem
        self.reader = reader
    }

    public func load(extends: String, from basePath: String) throws -> LoadedManifest {
        let resolvedPath = resolvePath(extends, relativeTo: basePath)
        let manifestPath = resolveManifestFile(at: resolvedPath)
        guard let path = manifestPath else {
            throw SpellbookError.missingExtendsParent(path: extends)
        }
        let manifest = try reader.read(at: path)
        return LoadedManifest(manifest: manifest, canonicalPath: path)
    }

    private func resolvePath(_ extends: String, relativeTo basePath: String) -> String {
        if extends.hasPrefix("/") { return standardize(extends) }
        if extends.hasPrefix("~") {
            let home = ProcessInfo.processInfo.environment["HOME"] ?? ""
            if extends == "~" { return home }
            return standardize(home + String(extends.dropFirst()))
        }
        let baseDir = (basePath as NSString).deletingLastPathComponent
        return standardize((baseDir as NSString).appendingPathComponent(extends))
    }

    private func standardize(_ path: String) -> String {
        (path as NSString).standardizingPath
    }

    private func resolveManifestFile(at path: String) -> String? {
        if path.hasSuffix(".yaml") || path.hasSuffix(".yml") {
            return fileSystem.probe(path) == .present ? path : nil
        }
        let visible = path + "/spells.yaml"
        if fileSystem.probe(visible) == .present { return visible }
        let hidden = path + "/.spells.yaml"
        if fileSystem.probe(hidden) == .present { return hidden }
        return nil
    }
}
