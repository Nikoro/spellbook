import Foundation
import Testing
@testable import SpellbookKit

final class StateFileTests {

    private let tempDir: String

    init() {
        tempDir = NSTemporaryDirectory() + "spellbook-state-test-\(UUID().uuidString)"
        try? FileManager.default.createDirectory(
            atPath: tempDir, withIntermediateDirectories: true
        )
    }

    deinit {
        try? FileManager.default.removeItem(atPath: tempDir)
    }

    // MARK: - Missing file

    @Test func read_missingFile_returnsNil() throws {
        let store = StateFile(path: tempDir + "/state.json")
        let result = try store.read()
        #expect(result == nil)
    }

    // MARK: - Round-trip

    @Test func writeAndRead_roundTrips() throws {
        let path = tempDir + "/state.json"
        let store = StateFile(path: path)
        let snapshot = StateSnapshot(
            updatedAt: "2026-04-13T10:30:00Z",
            projects: ["/proj": ProjectState(
                spellsYamlHash: "sha256:abc",
                chain: ["/proj/spells.yaml"],
                spells: ["hello": SpellState(
                    hash: "sha256:def",
                    wrapper: "/bin/hello",
                    origin: "/proj/spells.yaml"
                )]
            )]
        )

        try store.write(snapshot)
        let loaded = try store.read()

        #expect(loaded == snapshot)
    }

    // MARK: - Atomic overwrite

    @Test func write_overwritesExistingFile() throws {
        let path = tempDir + "/state.json"
        let store = StateFile(path: path)
        let first = StateSnapshot(updatedAt: "2026-04-13T10:00:00Z")
        let second = StateSnapshot(updatedAt: "2026-04-13T11:00:00Z")

        try store.write(first)
        try store.write(second)
        let loaded = try store.read()

        #expect(loaded?.updatedAt == "2026-04-13T11:00:00Z")
    }

    // MARK: - Version check

    @Test func read_unsupportedVersion_throws() throws {
        let path = tempDir + "/state.json"
        let json = """
        {"version": 99, "updated_at": "2026-04-13T10:00:00Z", "projects": {}}
        """
        try Data(json.utf8).write(to: URL(fileURLWithPath: path))

        let store = StateFile(path: path)
        #expect(throws: SpellbookError.unsupportedStateVersion(found: 99, supported: 1)) {
            try store.read()
        }
    }

    // MARK: - Creates directory

    @Test func write_createsParentDirectory() throws {
        let path = tempDir + "/nested/deep/state.json"
        let store = StateFile(path: path)

        try store.write(StateSnapshot(updatedAt: "2026-04-13T10:00:00Z"))

        let loaded = try store.read()
        #expect(loaded != nil)
    }
}
