import Foundation

public struct ManifestCacheReaderAdapter {
    private let spellbookHome: String
    private let fileManager: FileManager

    public init(spellbookHome: String, fileManager: FileManager = .default) {
        self.spellbookHome = spellbookHome
        self.fileManager = fileManager
    }

    public func cachePath(projectRootManifestPath: String) -> String {
        let hash = ManifestCacheCodec.projectHash(
            absoluteManifestPath: projectRootManifestPath
        )
        return spellbookHome + "/state/" + hash + "/manifest.bin"
    }

    public func readIfFresh(
        projectRootManifestPath: String
    ) -> DecodedManifestCache? {
        let path = cachePath(projectRootManifestPath: projectRootManifestPath)
        guard fileManager.fileExists(atPath: path) else { return nil }
        guard let cacheMtime = mtime(of: path) else { return nil }
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            return nil
        }
        guard let decoded = ManifestCacheCodec.decode(data) else { return nil }
        if anySourceNewer(than: cacheMtime, in: decoded.extendsChain) { return nil }
        return decoded
    }

    public func readAnyCache(
        projectRootManifestPath: String
    ) -> DecodedManifestCache? {
        let path = cachePath(projectRootManifestPath: projectRootManifestPath)
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            return nil
        }
        return ManifestCacheCodec.decode(data)
    }

    private func mtime(of path: String) -> Date? {
        let attrs = try? fileManager.attributesOfItem(atPath: path)
        return attrs?[.modificationDate] as? Date
    }

    private func anySourceNewer(than cacheMtime: Date, in chain: [String]) -> Bool {
        for source in chain {
            guard let sourceMtime = mtime(of: source) else { continue }
            if sourceMtime > cacheMtime { return true }
        }
        return false
    }
}
