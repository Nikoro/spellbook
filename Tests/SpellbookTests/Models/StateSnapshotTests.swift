import Foundation
import Testing
@testable import SpellbookKit

struct StateSnapshotTests {

    // MARK: - Round-trip encoding

    @Test func emptySnapshot_roundTrips() throws {
        let snapshot = StateSnapshot(updatedAt: "2026-04-13T10:30:00Z")
        let decoded = try roundTrip(snapshot)
        #expect(decoded == snapshot)
    }

    @Test func snapshotWithProject_roundTrips() throws {
        let snapshot = StateSnapshot(
            updatedAt: "2026-04-13T10:30:00Z",
            projects: ["/Users/me/proj": sampleProject()]
        )
        let decoded = try roundTrip(snapshot)
        #expect(decoded == snapshot)
    }

    @Test func version_defaultsToCurrentVersion() {
        let snapshot = StateSnapshot(updatedAt: "2026-04-13T10:30:00Z")
        #expect(snapshot.version == StateSnapshot.currentVersion)
        #expect(snapshot.version == 1)
    }

    // MARK: - JSON key format

    @Test func snakeCase_keysInJSON() throws {
        let snapshot = StateSnapshot(
            updatedAt: "2026-04-13T10:30:00Z",
            projects: ["/proj": sampleProject()]
        )
        let json = try encode(snapshot)
        #expect(json.contains("\"updated_at\""))
        #expect(json.contains("\"spells_yaml_hash\""))
        #expect(json.contains("\"updatedAt\"") == false)
        #expect(json.contains("\"spellsYamlHash\"") == false)
    }

    // MARK: - Stable hash inputs

    @Test func projectState_equalityIgnoresKeyOrder() {
        let spellsA: [String: SpellState] = [
            "hello": SpellState(hash: "sha256:a", wrapper: "/bin/hello", origin: "/p/spells.yaml"),
            "build": SpellState(hash: "sha256:b", wrapper: "/bin/build", origin: "/p/spells.yaml")
        ]
        let spellsB: [String: SpellState] = [
            "build": SpellState(hash: "sha256:b", wrapper: "/bin/build", origin: "/p/spells.yaml"),
            "hello": SpellState(hash: "sha256:a", wrapper: "/bin/hello", origin: "/p/spells.yaml")
        ]
        let projectA = ProjectState(spellsYamlHash: "sha256:x", chain: ["/p"], spells: spellsA)
        let projectB = ProjectState(spellsYamlHash: "sha256:x", chain: ["/p"], spells: spellsB)
        #expect(projectA == projectB)
    }

    // MARK: - Helpers

    private func sampleProject() -> ProjectState {
        ProjectState(
            spellsYamlHash: "sha256:abc",
            chain: ["/Users/me/spells.yaml", "/Users/me/proj/spells.yaml"],
            spells: [
                "hello": SpellState(
                    hash: "sha256:def",
                    wrapper: "/Users/me/.spellbook/bin/hello",
                    origin: "/Users/me/proj/spells.yaml"
                )
            ]
        )
    }

    private func roundTrip(_ snapshot: StateSnapshot) throws -> StateSnapshot {
        let data = try JSONEncoder().encode(snapshot)
        return try JSONDecoder().decode(StateSnapshot.self, from: data)
    }

    private func encode(_ snapshot: StateSnapshot) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(snapshot)
        return String(data: data, encoding: .utf8) ?? ""
    }
}
