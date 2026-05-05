public struct WrapperGenerator {
    private let writer: WrapperWriter
    private let binDirectory: String

    public init(writer: WrapperWriter, binDirectory: String) {
        self.writer = writer
        self.binDirectory = binDirectory
    }

    public func generate(
        manifest: SpellbookManifest
    ) throws -> [String: String] {
        let entries = collectEntrypoints(manifest)
        var writtenPaths: [String: String] = [:]
        do {
            for (entrypoint, spellName) in entries {
                let path = wrapperPath(for: entrypoint)
                let content = WrapperContent.render(spellName: spellName)
                try writer.writeWrapper(content: content, to: path)
                writtenPaths[entrypoint] = path
            }
        } catch {
            rollback(written: writtenPaths)
            throw error
        }
        return writtenPaths
    }

    private func collectEntrypoints(
        _ manifest: SpellbookManifest
    ) -> [(entrypoint: String, spellName: String)] {
        manifest.spells.flatMap { spell in
            var entries = [(spell.name, spell.name)]
            entries += spell.aliases.map { ($0, spell.name) }
            return entries
        }
    }

    private func wrapperPath(for entrypoint: String) -> String {
        if binDirectory.hasSuffix("/") {
            return binDirectory + entrypoint
        }
        return binDirectory + "/" + entrypoint
    }

    private func rollback(written: [String: String]) {
        for path in written.values {
            try? writer.removeWrapper(at: path)
        }
    }
}
