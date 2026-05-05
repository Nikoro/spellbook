import Testing
@testable import SpellbookKit

struct WrapperGeneratorTests {

    // MARK: - Canonical names

    @Test func singleSpell_writesOneWrapper() throws {
        let writer = MockWrapperWriter()
        let paths = try generate(
            spells: [SpellDefinition(name: "hello", script: "echo hi")],
            writer: writer
        )

        #expect(paths.count == 1)
        #expect(paths["hello"] == "/bin/hello")
        #expect(writer.writtenFiles["/bin/hello"] != nil)
    }

    // MARK: - Aliases

    @Test func aliases_produceAdditionalWrappers() throws {
        let writer = MockWrapperWriter()
        let spell = SpellDefinition(
            identity: SpellIdentity(name: "test", aliases: ["t", "check"]),
            body: SpellBody(script: "swift test")
        )
        let paths = try generate(spells: [spell], writer: writer)

        #expect(paths.count == 3)
        #expect(paths["test"] == "/bin/test")
        #expect(paths["t"] == "/bin/t")
        #expect(paths["check"] == "/bin/check")
    }

    @Test func aliasWrapper_dispatchesToCanonicalName() throws {
        let writer = MockWrapperWriter()
        let spell = SpellDefinition(
            identity: SpellIdentity(name: "deploy", aliases: ["d"]),
            body: SpellBody(script: "./deploy.sh")
        )
        _ = try generate(spells: [spell], writer: writer)

        let aliasContent = writer.writtenFiles["/bin/d"] ?? ""
        #expect(aliasContent.contains("\"deploy\""))
    }

    // MARK: - Multiple spells

    @Test func multipleSpells_writeAllWrappers() throws {
        let writer = MockWrapperWriter()
        let paths = try generate(
            spells: [
                SpellDefinition(name: "build", script: "make"),
                SpellDefinition(name: "test", script: "make test")
            ],
            writer: writer
        )

        #expect(paths.count == 2)
        #expect(writer.writtenFiles.count == 2)
    }

    // MARK: - Rollback on failure

    @Test func writeFailure_rollsBackPreviousWrappers() {
        let writer = MockWrapperWriter()
        let spells = [
            SpellDefinition(name: "first", script: "echo 1"),
            SpellDefinition(name: "second", script: "echo 2")
        ]

        writer.failAfterCount = 1

        #expect(throws: WrapperWriteError.simulatedFailure) {
            try generate(spells: spells, writer: writer)
        }
        #expect(writer.writtenFiles.isEmpty)
        #expect(writer.removedPaths.contains("/bin/first"))
    }

    // MARK: - Helpers

    @discardableResult
    private func generate(
        spells: [SpellDefinition],
        writer: MockWrapperWriter,
        binDir: String = "/bin"
    ) throws -> [String: String] {
        let manifest = SpellbookManifest(spells: spells)
        return try WrapperGenerator(writer: writer, binDirectory: binDir)
            .generate(manifest: manifest)
    }
}
