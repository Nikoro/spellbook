import Testing
@testable import SpellbookKit

struct ExtendsResolverTests {
    @Test func noExtends_returnsManifestUnchanged() throws {
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(name: "build", script: "./build")
        ])
        let loader = MockManifestLoader()
        let resolver = ExtendsResolver(loader: loader)

        let resolved = try resolver.resolve(manifest, basePath: "/repo/spells.yaml")

        #expect(resolved.spells.map(\.name) == ["build"])
        #expect(loader.loadCalls == [])
    }

    @Test func singleParent_mergesCloserWins() throws {
        let parent = SpellbookManifest(spells: [
            SpellDefinition(name: "build", script: "./parent-build"),
            SpellDefinition(name: "deploy", script: "./parent-deploy")
        ])
        let child = SpellbookManifest(extends: "../base/spells.yaml", spells: [
            SpellDefinition(name: "build", script: "./child-build")
        ])
        let loader = MockManifestLoader()
        loader.responses["../base/spells.yaml"] = LoadedManifest(
            manifest: parent, canonicalPath: "/repo/base/spells.yaml"
        )

        let resolved = try ExtendsResolver(loader: loader)
            .resolve(child, basePath: "/repo/project/spells.yaml")

        #expect(resolved.extends == nil)
        #expect(resolved.spells.map(\.name) == ["build", "deploy"])
        #expect(resolved.spells.first { $0.name == "build" }?.script == "./child-build")
        #expect(loader.loadCalls == [
            .init(extends: "../base/spells.yaml", basePath: "/repo/project/spells.yaml")
        ])
    }

    @Test func chain_walksMultipleParentsCloserWins() throws {
        let grandparent = SpellbookManifest(spells: [
            SpellDefinition(name: "a", script: "./gp-a"),
            SpellDefinition(name: "b", script: "./gp-b"),
            SpellDefinition(name: "c", script: "./gp-c")
        ])
        let parent = SpellbookManifest(extends: "../gp/spells.yaml", spells: [
            SpellDefinition(name: "b", script: "./p-b")
        ])
        let child = SpellbookManifest(extends: "../parent/spells.yaml", spells: [
            SpellDefinition(name: "a", script: "./c-a")
        ])
        let loader = MockManifestLoader()
        loader.responses["../parent/spells.yaml"] = LoadedManifest(
            manifest: parent, canonicalPath: "/repo/parent/spells.yaml"
        )
        loader.responses["../gp/spells.yaml"] = LoadedManifest(
            manifest: grandparent, canonicalPath: "/repo/gp/spells.yaml"
        )

        let resolved = try ExtendsResolver(loader: loader)
            .resolve(child, basePath: "/repo/child/spells.yaml")

        #expect(resolved.extends == nil)
        #expect(resolved.spells.map(\.name) == ["a", "b", "c"])
        #expect(resolved.spells.first { $0.name == "a" }?.script == "./c-a")
        #expect(resolved.spells.first { $0.name == "b" }?.script == "./p-b")
        #expect(resolved.spells.first { $0.name == "c" }?.script == "./gp-c")
        #expect(loader.loadCalls == [
            .init(extends: "../parent/spells.yaml", basePath: "/repo/child/spells.yaml"),
            .init(extends: "../gp/spells.yaml", basePath: "/repo/parent/spells.yaml")
        ])
    }

    @Test func missingParent_throws() {
        let child = SpellbookManifest(extends: "../nope.yaml", spells: [])
        let loader = MockManifestLoader()
        loader.errors["../nope.yaml"] = .missingExtendsParent(path: "../nope.yaml")

        #expect(throws: SpellbookError.missingExtendsParent(path: "../nope.yaml")) {
            try ExtendsResolver(loader: loader).resolve(child, basePath: "/repo/spells.yaml")
        }
    }

    @Test func cycle_throwsExtendsCycle() {
        let aManifest = SpellbookManifest(extends: "./b.yaml", spells: [])
        let bManifest = SpellbookManifest(extends: "./a.yaml", spells: [])
        let loader = MockManifestLoader()
        loader.responses["./b.yaml"] = LoadedManifest(
            manifest: bManifest, canonicalPath: "/repo/b.yaml"
        )
        loader.responses["./a.yaml"] = LoadedManifest(
            manifest: aManifest, canonicalPath: "/repo/a.yaml"
        )

        #expect(throws: SpellbookError.extendsCycle(path: "/repo/a.yaml")) {
            try ExtendsResolver(loader: loader).resolve(aManifest, basePath: "/repo/a.yaml")
        }
    }
}
