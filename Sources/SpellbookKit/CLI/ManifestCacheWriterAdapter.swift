import Foundation

public struct ManifestCacheWriterAdapter {
    private let spellbookHome: String
    private let fileManager: FileManager

    public init(spellbookHome: String, fileManager: FileManager = .default) {
        self.spellbookHome = spellbookHome
        self.fileManager = fileManager
    }

    public func writeIfPossible(
        merged: SpellbookManifest,
        extendsChain: [String],
        projectRootManifestPath: String
    ) {
        let hash = ManifestCacheCodec.projectHash(
            absoluteManifestPath: projectRootManifestPath
        )
        let directory = spellbookHome + "/state/" + hash
        let finalPath = directory + "/manifest.bin"
        let tempPath = finalPath + ".tmp"
        let payload = ManifestCacheCodec.encode(
            manifest: merged, extendsChain: extendsChain
        )
        writeAtomically(payload: payload, directory: directory,
                        tempPath: tempPath, finalPath: finalPath)
    }

    private func writeAtomically(
        payload: Data, directory: String, tempPath: String, finalPath: String
    ) {
        do {
            try fileManager.createDirectory(
                atPath: directory, withIntermediateDirectories: true
            )
            try payload.write(to: URL(fileURLWithPath: tempPath))
            if fileManager.fileExists(atPath: finalPath) {
                try fileManager.removeItem(atPath: finalPath)
            }
            try fileManager.moveItem(atPath: tempPath, toPath: finalPath)
        } catch {
            // Best-effort: swallow any filesystem error.
            _ = try? fileManager.removeItem(atPath: tempPath)
        }
    }
}
