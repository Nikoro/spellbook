import Testing
@testable import SpellbookKit

struct BootstrapResolverTests {

    private let binDir = "/Users/me/.spellbook/bin"
    private let home = "/Users/me"

    private func resolve(
        pathEnv: String? = "/usr/bin",
        shell: String? = "zsh",
        isTTY: Bool = true,
        rcFileContent: String? = nil
    ) -> BootstrapDecision {
        BootstrapResolver.resolve(BootstrapInput(
            pathEnv: pathEnv, spellbookBinDir: binDir,
            shell: shell, home: home, isTTY: isTTY,
            rcFileContent: rcFileContent
        ))
    }

    // MARK: - Already configured

    @Test func binDirInPath_returnsAlreadyConfigured() {
        #expect(resolve(pathEnv: "/usr/bin:\(binDir):/usr/local/bin") == .alreadyConfigured)
    }

    @Test func rcFileHasMarker_returnsAlreadyConfigured() {
        let rcFile = "some stuff\n# spellbook\neval \"$(spells init zsh)\"\n"
        #expect(resolve(rcFileContent: rcFile) == .alreadyConfigured)
    }

    // MARK: - Interactive offers

    @Test func tty_zsh_offersInteractive() {
        guard case let .offerInteractive(shell, rcPath, line) = resolve() else {
            Issue.record("Expected .offerInteractive"); return
        }
        #expect(shell == "zsh")
        #expect(rcPath == "/Users/me/.zshrc")
        #expect(line.contains("spells init zsh"))
    }

    @Test func tty_bash_offersInteractive() {
        guard case let .offerInteractive(shell, rcPath, line) = resolve(shell: "bash") else {
            Issue.record("Expected .offerInteractive"); return
        }
        #expect(shell == "bash")
        #expect(rcPath == "/Users/me/.bashrc")
        #expect(line.contains("spells init bash"))
    }

    @Test func tty_fish_offersInteractive() {
        guard case let .offerInteractive(shell, rcPath, line) = resolve(shell: "fish") else {
            Issue.record("Expected .offerInteractive"); return
        }
        #expect(shell == "fish")
        #expect(rcPath == "/Users/me/.config/fish/config.fish")
        #expect(line.contains("spells init fish | source"))
    }

    // MARK: - Non-TTY

    @Test func nonTTY_zsh_printsManual() {
        guard case let .printManual(shell, line) = resolve(isTTY: false) else {
            Issue.record("Expected .printManual"); return
        }
        #expect(shell == "zsh")
        #expect(line.contains("spells init zsh"))
    }

    @Test func nonTTY_fish_printsManual() {
        guard case let .printManual(shell, line) = resolve(shell: "fish", isTTY: false) else {
            Issue.record("Expected .printManual"); return
        }
        #expect(shell == "fish")
        #expect(line.contains("spells init fish | source"))
    }

    // MARK: - Unknown shell

    @Test func unknownShell_returnsUnknownShell() {
        #expect(resolve(shell: "nushell") == .unknownShell)
    }

    @Test func nilShell_returnsUnknownShell() {
        #expect(resolve(shell: nil) == .unknownShell)
    }

    // MARK: - Edge cases

    @Test func nilPath_offersBootstrap() {
        guard case .offerInteractive = resolve(pathEnv: nil) else {
            Issue.record("Expected .offerInteractive"); return
        }
    }

    @Test func emptyRcContent_offersBootstrap() {
        guard case .offerInteractive = resolve(rcFileContent: "") else {
            Issue.record("Expected .offerInteractive"); return
        }
    }

    @Test func shellFullPath_extractsBasename() {
        guard case let .offerInteractive(shell, _, _) = resolve(shell: "/bin/zsh") else {
            Issue.record("Expected .offerInteractive"); return
        }
        #expect(shell == "zsh")
    }

    // MARK: - Integration line format

    @Test func zshLine_usesEvalForm() {
        guard case let .offerInteractive(_, _, line) = resolve() else {
            Issue.record("Expected .offerInteractive"); return
        }
        #expect(line == "eval \"$(spells init zsh)\"")
    }

    @Test func fishLine_usesPipeSource() {
        guard case let .offerInteractive(_, _, line) = resolve(shell: "fish") else {
            Issue.record("Expected .offerInteractive"); return
        }
        #expect(line == "spells init fish | source")
    }
}
