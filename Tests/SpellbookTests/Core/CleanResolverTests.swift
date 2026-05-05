import Testing
@testable import SpellbookKit

struct CleanResolverTests {

    @Test func named_presentInState_removesWrapperAndName() {
        let project = makeState(spells: [
            "hello": SpellState(hash: "h", wrapper: "/bin/hello", origin: "/p")
        ])
        let plan = CleanResolver.plan(scope: .named("hello"), manifest: nil, project: project)
        #expect(plan.wrappersToRemove == ["/bin/hello"])
        #expect(plan.stateNamesToForget == ["hello"])
        #expect(plan.clearProject == false)
    }

    @Test func named_missingFromState_noop() {
        let project = makeState(spells: [:])
        let plan = CleanResolver.plan(scope: .named("ghost"), manifest: nil, project: project)
        #expect(plan.wrappersToRemove.isEmpty)
        #expect(plan.stateNamesToForget.isEmpty)
    }

    @Test func all_clearsProject() {
        let project = makeState(spells: [
            "a": SpellState(hash: "h", wrapper: "/bin/a", origin: "/p"),
            "b": SpellState(hash: "h", wrapper: "/bin/b", origin: "/p")
        ])
        let plan = CleanResolver.plan(scope: .all, manifest: nil, project: project)
        #expect(plan.wrappersToRemove == ["/bin/a", "/bin/b"])
        #expect(plan.stateNamesToForget == ["a", "b"])
        #expect(plan.clearProject)
    }

    @Test func orphans_removesOnlySpellsMissingFromManifest() {
        let project = makeState(spells: [
            "kept": SpellState(hash: "h", wrapper: "/bin/kept", origin: "/p"),
            "orphan": SpellState(hash: "h", wrapper: "/bin/orphan", origin: "/p")
        ])
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(name: "kept", script: "echo keep")
        ])
        let plan = CleanResolver.plan(scope: .orphans, manifest: manifest, project: project)
        #expect(plan.wrappersToRemove == ["/bin/orphan"])
        #expect(plan.stateNamesToForget == ["orphan"])
        #expect(plan.clearProject == false)
    }

    @Test func orphans_noProject_isNoop() {
        let plan = CleanResolver.plan(scope: .orphans, manifest: nil, project: nil)
        #expect(plan.wrappersToRemove.isEmpty)
        #expect(plan.stateNamesToForget.isEmpty)
    }

    private func makeState(spells: [String: SpellState]) -> ProjectState {
        ProjectState(spellsYamlHash: "abc", chain: ["/project/spells.yaml"], spells: spells)
    }
}
