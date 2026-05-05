import Foundation

enum BootstrapSubcommand {
    static func check(binDir: String, home: String?, capabilities: TerminalCapabilities) {
        let env = ProcessInfo.processInfo.environment
        let command = BootstrapCommand(
            terminal: StandardTerminal(capabilities: capabilities),
            contentReader: FoundationManifestContentReader(),
            fileWriter: FoundationFileWriter(),
            pathEnv: env["PATH"],
            shellEnv: env["SHELL"],
            home: home,
            spellbookBinDir: binDir
        )
        command.run()
    }
}
