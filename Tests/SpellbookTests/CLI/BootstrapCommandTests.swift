import Testing
@testable import SpellbookKit

struct BootstrapCommandTests {

    private let binDir = "/Users/me/.spellbook/bin"
    private let home = "/Users/me"

    // MARK: - Interactive accept

    @Test func accept_writesRcFileWithMarker() {
        let env = makeEnvironment(isTTY: true)
        env.terminal.inputBytes = [0x79] // 'y'

        makeCommand(env, pathEnv: "/usr/bin", shell: "/bin/zsh").run()

        let written = env.writer.writtenFiles["/Users/me/.zshrc"] ?? ""
        #expect(written.contains("# spellbook"))
        #expect(written.contains("eval \"$(spells init zsh)\""))
    }

    @Test func accept_default_writesRcFile() {
        let env = makeEnvironment(isTTY: true)
        env.terminal.inputBytes = [0x0A] // Enter (default yes)

        makeCommand(env, pathEnv: "/usr/bin", shell: "/bin/zsh").run()

        #expect(env.writer.writtenFiles["/Users/me/.zshrc"] != nil)
    }

    @Test func accept_printsSourceInstructions() {
        let env = makeEnvironment(isTTY: true)
        env.terminal.inputBytes = [0x79] // 'y'

        makeCommand(env, pathEnv: "/usr/bin", shell: "/bin/zsh").run()

        let output = env.terminal.writtenLines.joined(separator: "\n")
        #expect(output.contains("source"))
        #expect(output.contains(".zshrc"))
    }

    // MARK: - Interactive decline

    @Test func decline_doesNotWriteFile() {
        let env = makeEnvironment(isTTY: true)
        env.terminal.inputBytes = [0x6E] // 'n'

        makeCommand(env, pathEnv: "/usr/bin", shell: "/bin/zsh").run()

        #expect(env.writer.writtenFiles.isEmpty)
    }

    @Test func decline_printsManualInstructions() {
        let env = makeEnvironment(isTTY: true)
        env.terminal.inputBytes = [0x6E] // 'n'

        makeCommand(env, pathEnv: "/usr/bin", shell: "/bin/zsh").run()

        let output = env.terminal.writtenLines.joined(separator: "\n")
        #expect(output.contains("Add this to your shell config"))
        #expect(output.contains("eval \"$(spells init zsh)\""))
    }

    // MARK: - Non-TTY

    @Test func nonTTY_doesNotWriteFile() {
        let env = makeEnvironment(isTTY: false)

        makeCommand(env, pathEnv: "/usr/bin", shell: "/bin/zsh").run()

        #expect(env.writer.writtenFiles.isEmpty)
    }

    @Test func nonTTY_printsManualInstructions() {
        let env = makeEnvironment(isTTY: false)

        makeCommand(env, pathEnv: "/usr/bin", shell: "/bin/zsh").run()

        let output = env.terminal.writtenLines.joined(separator: "\n")
        #expect(output.contains("Add this to your shell config"))
    }

    // MARK: - Already configured

    @Test func alreadyInPath_noOutput() {
        let env = makeEnvironment(isTTY: true)

        makeCommand(env, pathEnv: binDir + ":/usr/bin", shell: "/bin/zsh").run()

        #expect(env.terminal.writtenLines.isEmpty)
        #expect(env.writer.writtenFiles.isEmpty)
    }

    @Test func rcHasMarker_noOutput() {
        let env = makeEnvironment(isTTY: true)
        env.reader.contents["/Users/me/.zshrc"] = "stuff\n# spellbook\neval stuff\n"

        makeCommand(env, pathEnv: "/usr/bin", shell: "/bin/zsh").run()

        #expect(env.terminal.writtenLines.isEmpty)
        #expect(env.writer.writtenFiles.isEmpty)
    }

    // MARK: - Fish

    @Test func fish_usesCorrectRcPath() {
        let env = makeEnvironment(isTTY: true)
        env.terminal.inputBytes = [0x79] // 'y'

        makeCommand(env, pathEnv: "/usr/bin", shell: "/bin/fish").run()

        let written = env.writer.writtenFiles["/Users/me/.config/fish/config.fish"] ?? ""
        #expect(written.contains("spells init fish | source"))
    }

    // MARK: - Append preserves existing content

    @Test func appendPreservesExistingContent() {
        let env = makeEnvironment(isTTY: true)
        env.reader.contents["/Users/me/.zshrc"] = "export FOO=bar\n"
        env.terminal.inputBytes = [0x79] // 'y'

        makeCommand(env, pathEnv: "/usr/bin", shell: "/bin/zsh").run()

        let written = env.writer.writtenFiles["/Users/me/.zshrc"] ?? ""
        #expect(written.hasPrefix("export FOO=bar\n"))
        #expect(written.contains("# spellbook"))
    }

    // MARK: - Helpers

    private final class Environment {
        let terminal: MockTerminal
        let reader: MockManifestContentReader
        let writer: MockFileWriter

        init(terminal: MockTerminal, reader: MockManifestContentReader, writer: MockFileWriter) {
            self.terminal = terminal
            self.reader = reader
            self.writer = writer
        }
    }

    private func makeEnvironment(isTTY: Bool) -> Environment {
        let caps = TerminalCapabilities(isTTY: isTTY, supportsColor: false, supportsRawMode: false)
        return Environment(
            terminal: MockTerminal(capabilities: caps),
            reader: MockManifestContentReader(),
            writer: MockFileWriter()
        )
    }

    private func makeCommand(
        _ env: Environment,
        pathEnv: String?,
        shell: String?
    ) -> BootstrapCommand {
        BootstrapCommand(
            terminal: env.terminal,
            contentReader: env.reader,
            fileWriter: env.writer,
            pathEnv: pathEnv,
            shellEnv: shell,
            home: home,
            spellbookBinDir: binDir
        )
    }
}
