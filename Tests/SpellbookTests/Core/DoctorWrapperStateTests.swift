import Testing
@testable import SpellbookKit

struct DoctorWrapperStateTests {

    private let resolver = DoctorResolver()
    private let binDir = "/Users/me/.spellbook/bin"

    @Test func noStateFile_producesInfo() {
        let report = diagnose(spellCount: 1, stateSnapshot: nil)
        let items = report.items.filter { $0.category == .wrappers }
        #expect(items.count == 1)
        #expect(items[0].severity == .info)
    }

    @Test func projectNotInState_producesWarning() {
        let snapshot = StateSnapshot(updatedAt: "2026-01-01T00:00:00Z")
        let report = diagnose(spellCount: 1, stateSnapshot: snapshot)
        let items = report.items.filter { $0.category == .wrappers }
        #expect(items[0].severity == .warning)
        #expect(items[0].message.contains("not yet activated"))
    }

    @Test func wrappersUpToDate_producesInfo() {
        let snapshot = StateSnapshot(
            updatedAt: "2026-01-01T00:00:00Z",
            projects: ["/project": ProjectState(
                spellsYamlHash: "abc",
                chain: ["/project/spells.yaml"],
                spells: ["hello": SpellState(
                    hash: "def", wrapper: "/bin/hello",
                    origin: "/project/spells.yaml"
                )]
            )]
        )
        let report = diagnose(spellCount: 1, stateSnapshot: snapshot)
        let items = report.items.filter { $0.category == .wrappers }
        #expect(items.count == 1)
        #expect(items[0].severity == .info)
        #expect(items[0].message.contains("up to date"))
    }

    @Test func newSpellsNotActivated_producesWarning() {
        let snapshot = StateSnapshot(
            updatedAt: "2026-01-01T00:00:00Z",
            projects: ["/project": ProjectState(
                spellsYamlHash: "abc",
                chain: ["/project/spells.yaml"],
                spells: [:]
            )]
        )
        let report = diagnose(spellCount: 1, stateSnapshot: snapshot)
        let items = report.items.filter {
            $0.category == .wrappers && $0.severity == .warning
        }
        #expect(items.count == 1)
        #expect(items[0].message.contains("New spells"))
    }

    @Test func removedSpells_producesStaleWarning() {
        let snapshot = StateSnapshot(
            updatedAt: "2026-01-01T00:00:00Z",
            projects: ["/project": ProjectState(
                spellsYamlHash: "abc",
                chain: ["/project/spells.yaml"],
                spells: [
                    "hello": SpellState(
                        hash: "def", wrapper: "/bin/hello",
                        origin: "/project/spells.yaml"
                    ),
                    "old": SpellState(
                        hash: "ghi", wrapper: "/bin/old",
                        origin: "/project/spells.yaml"
                    )
                ]
            )]
        )
        let report = diagnose(spellCount: 1, stateSnapshot: snapshot)
        let items = report.items.filter {
            $0.category == .wrappers && $0.message.contains("Stale")
        }
        #expect(items.count == 1)
        #expect(items[0].message.contains("old"))
    }

    @Test func missingWrapperOnDisk_producesWarning() {
        let snapshot = StateSnapshot(
            updatedAt: "2026-01-01T00:00:00Z",
            projects: ["/project": ProjectState(
                spellsYamlHash: "abc",
                chain: ["/project/spells.yaml"],
                spells: ["hello": SpellState(
                    hash: "def", wrapper: "/bin/hello",
                    origin: "/project/spells.yaml"
                )]
            )]
        )
        let fileSystem = MockFileSystem()
        // bin/hello is intentionally absent — wrapper was removed manually.
        let report = diagnose(spellCount: 1, stateSnapshot: snapshot, fileSystem: fileSystem)
        let warnings = report.items.filter {
            $0.category == .wrappers && $0.severity == .warning
        }
        #expect(warnings.count == 1)
        #expect(warnings[0].message.contains("Missing wrappers"))
        #expect(warnings[0].message.contains("hello"))
    }

    @Test func wrappersPresentOnDisk_producesInfo() {
        let snapshot = StateSnapshot(
            updatedAt: "2026-01-01T00:00:00Z",
            projects: ["/project": ProjectState(
                spellsYamlHash: "abc",
                chain: ["/project/spells.yaml"],
                spells: ["hello": SpellState(
                    hash: "def", wrapper: "/bin/hello",
                    origin: "/project/spells.yaml"
                )]
            )]
        )
        let fileSystem = MockFileSystem()
        fileSystem.files.insert("/bin/hello")
        let report = diagnose(spellCount: 1, stateSnapshot: snapshot, fileSystem: fileSystem)
        let items = report.items.filter { $0.category == .wrappers }
        #expect(items.contains { $0.severity == .info && $0.message.contains("up to date") })
        #expect(!items.contains { $0.message.contains("Missing wrappers") })
    }

    @Test func stateError_producesError() {
        let report = resolver.diagnose(DoctorInput(
            activationResult: nil,
            activationError: .noManifestFound,
            pathEnv: binDir,
            spellbookBinDir: binDir,
            stateSnapshot: nil,
            stateError: .unsupportedStateVersion(found: 0, supported: 1)
        ))
        let stateItems = report.items.filter {
            $0.severity == .error && $0.message.hasPrefix("State:")
        }
        #expect(stateItems.count == 1)
        #expect(stateItems[0].message.contains("0"))
        #expect(stateItems[0].message.contains("1"))
    }

    @Test func removedInheritedSpell_reportsParentOrigin() throws {
        let snapshot = StateSnapshot(
            updatedAt: "2026-01-01T00:00:00Z",
            projects: ["/project": ProjectState(
                spellsYamlHash: "abc",
                chain: ["/parent/spells.yaml", "/project/spells.yaml"],
                spells: [
                    "hello": SpellState(
                        hash: "def", wrapper: "/bin/hello",
                        origin: "/project/spells.yaml"
                    ),
                    "shared": SpellState(
                        hash: "ghi", wrapper: "/bin/shared",
                        origin: "/parent/spells.yaml"
                    )
                ]
            )]
        )
        let report = diagnose(spellCount: 1, stateSnapshot: snapshot)
        let stale = report.items.first { $0.message.contains("Stale") }
        let message = try #require(stale?.message)
        #expect(message.contains("shared (was /parent/spells.yaml)"))
    }

    // MARK: - Helpers

    private func diagnose(
        spellCount: Int,
        stateSnapshot: StateSnapshot?,
        fileSystem: FileSystemProtocol? = nil
    ) -> DoctorReport {
        let spells = (0..<spellCount).map { index in
            SpellDefinition(
                name: "hello\(index > 0 ? "\(index)" : "")",
                script: "echo"
            )
        }
        let result = ActivationResult(
            manifest: SpellbookManifest(spells: spells),
            location: ManifestLocation(
                path: "/project/spells.yaml", source: .project
            ),
            chain: ["/project/spells.yaml"]
        )
        return resolver.diagnose(DoctorInput(
            activationResult: result,
            activationError: nil,
            pathEnv: binDir,
            spellbookBinDir: binDir,
            stateSnapshot: stateSnapshot,
            wrapperFileSystem: fileSystem
        ))
    }
}
