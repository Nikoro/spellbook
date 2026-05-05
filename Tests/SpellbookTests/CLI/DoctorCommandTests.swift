import Testing
@testable import SpellbookKit

struct DoctorCommandTests {

    private let binDir = "/Users/me/.spellbook/bin"

    @Test func healthyProject_exitCodeZero() {
        let env = makeEnvironment()
        env.fileSystem.files.insert("/project/spells.yaml")
        env.reader.manifests["/project/spells.yaml"] = SpellbookManifest(spells: [
            SpellDefinition(name: "hello", script: "echo hi")
        ])

        let output = makeCommand(env).run(cwd: "/project")

        #expect(output.exitCode == 0)
        #expect(output.report.hasErrors == false)
    }

    @Test func noManifest_exitCodeOne() {
        let env = makeEnvironment()
        let output = makeCommand(env).run(cwd: "/nowhere")

        #expect(output.exitCode == 1)
        #expect(output.report.hasErrors)
    }

    @Test func pathMissing_exitCodeOne() {
        let env = makeEnvironment(pathEnv: "/usr/bin:/usr/local/bin")
        env.fileSystem.files.insert("/project/spells.yaml")
        env.reader.manifests["/project/spells.yaml"] = SpellbookManifest(spells: [])

        let output = makeCommand(env).run(cwd: "/project")

        #expect(output.exitCode == 1)
        let errorLines = output.lines.filter { $0.hasPrefix("[ERROR]") }
        #expect(errorLines.contains { $0.contains("not in PATH") })
    }

    @Test func stateReadError_isReportedAsStateError() {
        let env = makeEnvironment()
        env.fileSystem.files.insert("/project/spells.yaml")
        env.reader.manifests["/project/spells.yaml"] = SpellbookManifest(spells: [])
        env.state.readError = SpellbookError.unsupportedStateVersion(found: 0, supported: 1)

        let output = makeCommand(env).run(cwd: "/project")

        let stateErrors = output.lines.filter {
            $0.hasPrefix("[ERROR]") && $0.contains("State:")
        }
        #expect(stateErrors.count == 1)
        #expect(output.exitCode == 1)
    }

    @Test func outputFormatsLines() {
        let env = makeEnvironment()
        env.fileSystem.files.insert("/project/spells.yaml")
        env.reader.manifests["/project/spells.yaml"] = SpellbookManifest(spells: [
            SpellDefinition(name: "hello", script: "echo hi")
        ])

        let output = makeCommand(env).run(cwd: "/project")

        #expect(output.lines.allSatisfy {
            $0.hasPrefix("[ERROR]") || $0.hasPrefix("[WARN]") || $0.hasPrefix("[INFO]")
        })
    }

    // MARK: - Helpers

    private struct TestEnvironment {
        let fileSystem: MockFileSystem
        let reader: MockManifestReader
        let loader: MockManifestLoader
        let state: MockStateStore
        let pathEnv: String?
    }

    private func makeEnvironment(pathEnv: String? = nil) -> TestEnvironment {
        TestEnvironment(
            fileSystem: MockFileSystem(),
            reader: MockManifestReader(),
            loader: MockManifestLoader(),
            state: MockStateStore(),
            pathEnv: pathEnv ?? "/Users/me/.spellbook/bin:/usr/bin"
        )
    }

    private func makeCommand(_ env: TestEnvironment) -> DoctorCommand {
        let resolver = ActivationResolver(
            fileSystem: env.fileSystem,
            manifestReader: env.reader,
            manifestLoader: env.loader
        )
        return DoctorCommand(
            resolver: resolver,
            stateStore: env.state,
            pathEnv: env.pathEnv,
            spellbookBinDir: binDir
        )
    }
}
