import Foundation

public struct BootstrapCommand {
    private let terminal: TerminalProtocol
    private let contentReader: ManifestContentReader
    private let fileWriter: FileWriter
    private let pathEnv: String?
    private let shellEnv: String?
    private let home: String?
    private let spellbookBinDir: String

    public init(
        terminal: TerminalProtocol,
        contentReader: ManifestContentReader,
        fileWriter: FileWriter,
        pathEnv: String?,
        shellEnv: String?,
        home: String?,
        spellbookBinDir: String
    ) {
        self.terminal = terminal
        self.contentReader = contentReader
        self.fileWriter = fileWriter
        self.pathEnv = pathEnv
        self.shellEnv = shellEnv
        self.home = home
        self.spellbookBinDir = spellbookBinDir
    }

    public func run() {
        let rcContent = readRcContent()
        let decision = BootstrapResolver.resolve(BootstrapInput(
            pathEnv: pathEnv,
            spellbookBinDir: spellbookBinDir,
            shell: shellEnv,
            home: home,
            isTTY: terminal.capabilities.isTTY,
            rcFileContent: rcContent
        ))

        switch decision {
        case .alreadyConfigured:
            break
        case let .offerInteractive(shell, rcPath, line):
            offerInteractive(shell: shell, rcPath: rcPath, line: line, existingContent: rcContent)
        case let .printManual(shell, line):
            printManualInstructions(shell: shell, line: line)
        case .unknownShell:
            break
        }
    }

    private func readRcContent() -> String? {
        guard let home,
              let shellName = BootstrapResolver.normalizedShellName(shellEnv) else { return nil }
        let rcPath = BootstrapResolver.rcFilePath(shell: shellName, home: home)
        return try? contentReader.readContent(at: rcPath)
    }

    private func offerInteractive(shell: String, rcPath: String, line: String, existingContent: String?) {
        terminal.writeLine("")
        terminal.writeLine("Shell integration not detected.")
        terminal.write("Add to \(rcPath)? [Y/n] ")

        let accepted = readYesNo()
        if accepted {
            appendToRcFile(rcPath: rcPath, line: line, existingContent: existingContent)
            terminal.writeLine("Added shell integration to \(rcPath). Restart your shell or run:")
            terminal.writeLine("  source \(rcPath)")
        } else {
            terminal.writeLine("")
            printManualInstructions(shell: shell, line: line)
        }
    }

    private func printManualInstructions(shell: String, line: String) {
        terminal.writeLine("Add this to your shell config:")
        terminal.writeLine("")
        terminal.writeLine("  # spellbook")
        terminal.writeLine("  \(line)")
    }

    private func readYesNo() -> Bool {
        guard let byte = try? terminal.readByte() else { return true }
        let char = Character(UnicodeScalar(byte))
        if char == "\n" || char == "\r" || char == "y" || char == "Y" { return true }
        return false
    }

    private func appendToRcFile(rcPath: String, line: String, existingContent: String?) {
        let existing = existingContent ?? ""
        let separator = existing.isEmpty || existing.hasSuffix("\n") ? "" : "\n"
        let block = "\(separator)\n# spellbook\n\(line)\n"
        let newContent = existing + block
        try? fileWriter.writeFile(content: newContent, to: rcPath)
    }

}
