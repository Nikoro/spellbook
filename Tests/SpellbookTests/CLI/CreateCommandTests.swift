import Testing
@testable import SpellbookKit

struct CreateCommandTests {

    @Test func create_writesManifest() throws {
        let fileSystem = MockFileSystem()
        let writer = MockFileWriter()
        let command = CreateCommand(fileSystem: fileSystem, fileWriter: writer)

        let path = try command.run(cwd: "/project")

        #expect(path == "/project/spells.yaml")
        let content = try #require(writer.writtenFiles["/project/spells.yaml"])
        #expect(content.contains("hello:"))
    }

    @Test func create_customName_writesNamedSpell() throws {
        let fileSystem = MockFileSystem()
        let writer = MockFileWriter()
        let command = CreateCommand(fileSystem: fileSystem, fileWriter: writer)

        _ = try command.run(cwd: "/project", spellName: "build")

        let content = try #require(writer.writtenFiles["/project/spells.yaml"])
        #expect(content.contains("build:"))
    }

    @Test func create_refusesOverwrite_visibleManifest() {
        let fileSystem = MockFileSystem()
        fileSystem.files.insert("/project/spells.yaml")
        let writer = MockFileWriter()
        let command = CreateCommand(fileSystem: fileSystem, fileWriter: writer)

        #expect(throws: SpellbookError.manifestAlreadyExists(path: "/project/spells.yaml")) {
            try command.run(cwd: "/project")
        }
        #expect(writer.writtenFiles.isEmpty)
    }

    @Test func create_refusesOverwrite_hiddenManifest() {
        let fileSystem = MockFileSystem()
        fileSystem.files.insert("/project/.spells.yaml")
        let writer = MockFileWriter()
        let command = CreateCommand(fileSystem: fileSystem, fileWriter: writer)

        #expect(throws: SpellbookError.manifestAlreadyExists(path: "/project/.spells.yaml")) {
            try command.run(cwd: "/project")
        }
    }

    @Test func create_invalidName_throwsError() {
        let fileSystem = MockFileSystem()
        let writer = MockFileWriter()
        let command = CreateCommand(fileSystem: fileSystem, fileWriter: writer)

        #expect(throws: SpellbookError.createInvalidName(name: "123")) {
            try command.run(cwd: "/project", spellName: "123")
        }
        #expect(writer.writtenFiles.isEmpty)
    }
}
