public enum BootstrapResolver {
    public static func resolve(_ input: BootstrapInput) -> BootstrapDecision {
        if let pathEnv = input.pathEnv {
            let components = pathEnv.split(separator: ":").map(String.init)
            if components.contains(input.spellbookBinDir) {
                return .alreadyConfigured
            }
        }

        if let content = input.rcFileContent, content.contains("# spellbook") {
            return .alreadyConfigured
        }

        let shellName = normalizedShell(input.shell)
        guard let shellName else { return .unknownShell }

        guard let home = input.home else { return .unknownShell }
        let rcPath = rcFilePath(shell: shellName, home: home)
        let line = integrationLine(shell: shellName)

        if input.isTTY {
            return .offerInteractive(shell: shellName, rcPath: rcPath, integrationLine: line)
        }
        return .printManual(shell: shellName, integrationLine: line)
    }

    private static func normalizedShell(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let basename: String
        if let lastSlash = raw.lastIndex(of: "/") {
            basename = String(raw[raw.index(after: lastSlash)...])
        } else {
            basename = raw
        }
        switch basename {
        case "zsh", "bash", "fish": return basename
        default: return nil
        }
    }

    static func rcFilePath(shell: String, home: String) -> String {
        switch shell {
        case "zsh": return home + "/.zshrc"
        case "bash": return home + "/.bashrc"
        case "fish": return home + "/.config/fish/config.fish"
        default: return home + "/.profile"
        }
    }

    static func normalizedShellName(_ raw: String?) -> String? {
        normalizedShell(raw)
    }

    private static func integrationLine(shell: String) -> String {
        switch shell {
        case "fish": return "spells init fish | source"
        default: return "eval \"$(spells init \(shell))\""
        }
    }
}
