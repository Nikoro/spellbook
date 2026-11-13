import Foundation
import Testing
@testable import SpellbookKit

struct ManifestCacheWriterFileTests {

    private func makeWriter(root: String) -> ManifestCacheWriterAdapter {
        ManifestCacheWriterAdapter(spellbookHome: root)
    }

    private func tempHome() -> String {
        let base = NSTemporaryDirectory() + "spellbook-cache-test-" + UUID().uuidString
        return base
    }

    private func makeManifest() -> SpellbookManifest {
        SpellbookManifest(spells: [SpellDefinition(name: "hello", script: "echo hi")])
    }

    @Test func writeIfPossible_writesReadableArtifact() throws {
        let home = tempHome()
        defer { try? FileManager.default.removeItem(atPath: home) }
        let writer = makeWriter(root: home)
        let manifest = makeManifest()
        let projectManifestPath = "/tmp/proj/spells.yaml"

        writer.writeIfPossible(
            merged: manifest,
            extendsChain: [projectManifestPath],
            projectRootManifestPath: projectManifestPath
        )

        let projectHash = ManifestCacheCodec.projectHash(
            absoluteManifestPath: projectManifestPath
        )
        let expectedPath = home + "/state/" + projectHash + "/manifest.bin"
        #expect(FileManager.default.fileExists(atPath: expectedPath))

        let data = try Data(contentsOf: URL(fileURLWithPath: expectedPath))
        let decoded = try #require(ManifestCacheCodec.decode(data))
        #expect(decoded.merged == manifest)
        #expect(decoded.extendsChain == [projectManifestPath])
    }

    @Test func writeIfPossible_overwritesAtomically() throws {
        let home = tempHome()
        defer { try? FileManager.default.removeItem(atPath: home) }
        let writer = makeWriter(root: home)
        let projectManifestPath = "/tmp/proj/spells.yaml"
        let manifest1 = makeManifest()
        let manifest2 = SpellbookManifest(spells: [
            SpellDefinition(name: "hello", script: "echo hi"),
            SpellDefinition(name: "bye", script: "echo bye")
        ])

        writer.writeIfPossible(
            merged: manifest1, extendsChain: [projectManifestPath],
            projectRootManifestPath: projectManifestPath
        )
        writer.writeIfPossible(
            merged: manifest2, extendsChain: [projectManifestPath],
            projectRootManifestPath: projectManifestPath
        )

        let projectHash = ManifestCacheCodec.projectHash(
            absoluteManifestPath: projectManifestPath
        )
        let expectedPath = home + "/state/" + projectHash + "/manifest.bin"
        let data = try Data(contentsOf: URL(fileURLWithPath: expectedPath))
        let decoded = try #require(ManifestCacheCodec.decode(data))
        #expect(decoded.merged == manifest2)

        #expect(!FileManager.default.fileExists(atPath: expectedPath + ".tmp"))
    }

    @Test func writeIfPossible_swallowsErrors_whenPathIsUnwritable() {
        let writer = makeWriter(root: "/dev/null/unwritable")
        writer.writeIfPossible(
            merged: makeManifest(),
            extendsChain: [],
            projectRootManifestPath: "/tmp/proj/spells.yaml"
        )
    }
}
