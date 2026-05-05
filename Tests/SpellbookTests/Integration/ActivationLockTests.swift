import Testing
@testable import SpellbookKit

struct ActivationLockTests {

    @Test func activation_holdsExclusiveLockAcrossWrites() throws {
        let env = makeEnv()
        let lock = RecordingFileLock()

        _ = try makeCommand(env, fileLock: lock).activate(cwd: "/project")

        #expect(lock.acquireCount == 1)
        #expect(env.writer.writtenFiles.count == 1)
        #expect(env.state.stored != nil)
    }

    @Test func activation_failureInsideLockReleasesLock() throws {
        let env = makeEnv()
        env.state.writeError = SpellbookError.noManifestFound
        let lock = RecordingFileLock()

        #expect(throws: (any Error).self) {
            try makeCommand(env, fileLock: lock).activate(cwd: "/project")
        }
        #expect(lock.acquireCount == 1)
        #expect(lock.releaseCount == 1)
    }

    @Test func activation_withoutLock_stillSucceeds() throws {
        let env = makeEnv()
        _ = try makeCommand(env, fileLock: nil).activate(cwd: "/project")
        #expect(env.state.stored != nil)
    }

    // MARK: - Helpers

    private struct Env {
        let fileSystem: MockFileSystem
        let reader: MockManifestReader
        let loader: MockManifestLoader
        let writer: MockWrapperWriter
        let state: MockStateStore
        let content: MockManifestContentReader
    }

    private func makeEnv() -> Env {
        let env = Env(
            fileSystem: MockFileSystem(),
            reader: MockManifestReader(),
            loader: MockManifestLoader(),
            writer: MockWrapperWriter(),
            state: MockStateStore(),
            content: MockManifestContentReader()
        )
        env.fileSystem.files.insert("/project/spells.yaml")
        env.reader.manifests["/project/spells.yaml"] = SpellbookManifest(spells: [
            SpellDefinition(name: "hello", script: "echo hi")
        ])
        return env
    }

    private func makeCommand(_ env: Env, fileLock: FileLock?) -> ActivationCommand {
        ActivationCommand(
            resolver: ActivationResolver(
                fileSystem: env.fileSystem,
                manifestReader: env.reader,
                manifestLoader: env.loader
            ),
            wrapperGenerator: WrapperGenerator(
                writer: env.writer,
                binDirectory: "/home/.spellbook/bin"
            ),
            stateStore: env.state,
            manifestContent: env.content,
            fileLock: fileLock
        )
    }
}
