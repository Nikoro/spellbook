import Testing
@testable import SpellbookKit

struct StaleDiagnosticTests {

    @Test func noState_returnsNoState() {
        let result = StaleDiagnostic.diagnose(spellName: "hello", state: nil)
        #expect(result == .noState)
    }

    @Test func emptyState_returnsNotFoundAnywhere() {
        let state = StateSnapshot(updatedAt: "2026-01-01T00:00:00Z")
        let result = StaleDiagnostic.diagnose(spellName: "hello", state: state)
        #expect(result == .notFoundAnywhere)
    }

    @Test func spellNotInAnyProject_returnsNotFoundAnywhere() {
        let state = StateSnapshot(
            updatedAt: "2026-01-01T00:00:00Z",
            projects: [
                "/project-a": ProjectState(
                    spellsYamlHash: "sha256:abc",
                    chain: ["/project-a/spells.yaml"],
                    spells: ["build": SpellState(
                        hash: "sha256:def", wrapper: "/bin/build", origin: "/project-a/spells.yaml"
                    )]
                )
            ]
        )
        let result = StaleDiagnostic.diagnose(spellName: "deploy", state: state)
        #expect(result == .notFoundAnywhere)
    }

    @Test func spellInOneProject_returnsMatch() {
        let state = StateSnapshot(
            updatedAt: "2026-01-01T00:00:00Z",
            projects: [
                "/project-a": ProjectState(
                    spellsYamlHash: "sha256:abc",
                    chain: ["/project-a/spells.yaml"],
                    spells: ["hello": SpellState(
                        hash: "sha256:def",
                        wrapper: "/bin/hello",
                        origin: "/project-a/spells.yaml"
                    )]
                )
            ]
        )
        let result = StaleDiagnostic.diagnose(spellName: "hello", state: state)
        #expect(result == .foundInProjects([
            ProjectMatch(projectPath: "/project-a", originManifest: "/project-a/spells.yaml")
        ]))
    }

    @Test func spellInMultipleProjects_returnsAllSorted() {
        let state = StateSnapshot(
            updatedAt: "2026-01-01T00:00:00Z",
            projects: [
                "/project-b": ProjectState(
                    spellsYamlHash: "sha256:b",
                    chain: ["/project-b/spells.yaml"],
                    spells: ["deploy": SpellState(
                        hash: "sha256:1", wrapper: "/bin/deploy", origin: "/project-b/spells.yaml"
                    )]
                ),
                "/project-a": ProjectState(
                    spellsYamlHash: "sha256:a",
                    chain: ["/project-a/spells.yaml"],
                    spells: ["deploy": SpellState(
                        hash: "sha256:2", wrapper: "/bin/deploy", origin: "/project-a/spells.yaml"
                    )]
                )
            ]
        )
        let result = StaleDiagnostic.diagnose(spellName: "deploy", state: state)
        #expect(result == .foundInProjects([
            ProjectMatch(projectPath: "/project-a", originManifest: "/project-a/spells.yaml"),
            ProjectMatch(projectPath: "/project-b", originManifest: "/project-b/spells.yaml")
        ]))
    }
}
