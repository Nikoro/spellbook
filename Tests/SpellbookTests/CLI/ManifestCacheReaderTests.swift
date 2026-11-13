import Foundation
import Testing
@testable import SpellbookKit

struct ManifestCacheReaderTests {
    @Test func cacheHookWritesOriginsAndFreshnessRejectsNewerSource() throws {
        let home = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: home) }
        try FileManager.default.createDirectory(at: home, withIntermediateDirectories: true)
        let path = home.appendingPathComponent("spells.yaml").path
        try "hello: echo hi".write(toFile: path, atomically: true, encoding: .utf8)
        let manifest = SpellbookManifest(spells: [SpellDefinition(name: "hello", script: "echo hi")])
        let result = ActivationResult(
            manifest: manifest, location: ManifestLocation(path: path, source: .project), chain: []
        )
        let reader = ManifestCacheReaderAdapter(spellbookHome: home.path)
        #expect(reader.readAnyCache(projectRootManifestPath: path) == nil)
        ManifestCacheHook.writeIfPossible(writer: ManifestCacheWriterAdapter(spellbookHome: home.path), result: result)
        let decoded = try #require(reader.readIfFresh(projectRootManifestPath: path))
        #expect(decoded.merged == manifest)
        #expect(decoded.extendsChain == [path])
        try FileManager.default.setAttributes([.modificationDate: Date.distantFuture], ofItemAtPath: path)
        #expect(reader.readIfFresh(projectRootManifestPath: path) == nil)
        #expect(reader.readAnyCache(projectRootManifestPath: path)?.merged == manifest)
    }

    @Test func corruptCacheDoesNotProduceAManifest() throws {
        let home = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: home) }
        let reader = ManifestCacheReaderAdapter(spellbookHome: home.path)
        let path = reader.cachePath(projectRootManifestPath: "/project/spells.yaml")
        let parent = URL(fileURLWithPath: path).deletingLastPathComponent()
        try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
        try Data("broken".utf8).write(to: URL(fileURLWithPath: path))
        #expect(reader.readAnyCache(projectRootManifestPath: "/project/spells.yaml") == nil)
        #expect(reader.readIfFresh(projectRootManifestPath: "/project/spells.yaml") == nil)
    }
}
