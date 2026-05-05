import Testing
@testable import SpellbookKit

struct DiffDetectorTests {

    @Test func noState_everythingIsAdded() {
        let fresh = makeResult(spells: [
            SpellDefinition(name: "build", script: "make"),
            SpellDefinition(name: "test", script: "swift test")
        ])
        let entries = DiffDetector.detect(fresh: fresh, state: nil)
        #expect(entries.count == 2)
        #expect(entries.allSatisfy { $0.kind == .added })
        #expect(entries.map(\.name) == ["build", "test"])
    }

    @Test func unchangedSpell_isNotReported() {
        let spell = SpellDefinition(name: "build", script: "make")
        let fresh = makeResult(spells: [spell])
        let state = ProjectState(
            spellsYamlHash: "abc",
            chain: ["/project/spells.yaml"],
            spells: [
                "build": SpellState(
                    hash: ManifestHasher.hashSpell(spell),
                    wrapper: "/bin/build",
                    origin: "/project/spells.yaml"
                )
            ]
        )
        #expect(DiffDetector.detect(fresh: fresh, state: state).isEmpty)
    }

    @Test func changedScript_reportsChanged() {
        let state = ProjectState(
            spellsYamlHash: "abc",
            chain: ["/project/spells.yaml"],
            spells: [
                "build": SpellState(
                    hash: "stale-hash",
                    wrapper: "/bin/build",
                    origin: "/project/spells.yaml"
                )
            ]
        )
        let fresh = makeResult(spells: [SpellDefinition(name: "build", script: "make all")])
        let entries = DiffDetector.detect(fresh: fresh, state: state)
        #expect(entries == [DiffEntry(name: "build", kind: .changed, origin: "/project/spells.yaml")])
    }

    @Test func missingFromFresh_reportsRemoved() {
        let state = ProjectState(
            spellsYamlHash: "abc",
            chain: ["/project/spells.yaml"],
            spells: [
                "old": SpellState(
                    hash: "hash",
                    wrapper: "/bin/old",
                    origin: "/parent/spells.yaml"
                )
            ]
        )
        let fresh = makeResult(spells: [])
        let entries = DiffDetector.detect(fresh: fresh, state: state)
        #expect(entries == [DiffEntry(name: "old", kind: .removed, origin: "/parent/spells.yaml")])
    }

    @Test func mixedAddedChangedRemoved_sortsByKindThenName() {
        let kept = SpellDefinition(name: "build", script: "make")
        let changed = SpellDefinition(name: "test", script: "swift test --new")
        let added = SpellDefinition(name: "deploy", script: "./deploy")
        let state = mixedState(keepingHashOf: kept)
        let fresh = makeResult(spells: [kept, changed, added])
        let entries = DiffDetector.detect(fresh: fresh, state: state)
        #expect(entries.map { "\($0.kind) \($0.name)" } == [
            "added deploy",
            "changed test",
            "removed lint"
        ])
    }

    private func mixedState(keepingHashOf kept: SpellDefinition) -> ProjectState {
        ProjectState(
            spellsYamlHash: "abc",
            chain: ["/project/spells.yaml"],
            spells: [
                "build": SpellState(
                    hash: ManifestHasher.hashSpell(kept),
                    wrapper: "/bin/build", origin: "/project/spells.yaml"
                ),
                "test": SpellState(hash: "old-hash", wrapper: "/bin/test", origin: "/project/spells.yaml"),
                "lint": SpellState(hash: "hash", wrapper: "/bin/lint", origin: "/project/spells.yaml")
            ]
        )
    }

    private func makeResult(
        spells: [SpellDefinition],
        origins: [String: String] = [:]
    ) -> ActivationResult {
        ActivationResult(
            manifest: SpellbookManifest(spells: spells),
            location: ManifestLocation(
                path: "/project/spells.yaml", source: .project
            ),
            chain: ["/project/spells.yaml"],
            spellOrigins: origins
        )
    }
}
