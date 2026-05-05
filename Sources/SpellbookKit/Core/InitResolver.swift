public enum InitResolver {
    public static func shellSnippet(shell: String) throws -> String {
        switch shell {
        case "zsh": return ShellIntegrationScripts.script(for: .zsh)
        case "bash": return ShellIntegrationScripts.script(for: .bash)
        case "fish": return ShellIntegrationScripts.script(for: .fish)
        default: throw SpellbookError.unsupportedShell(name: shell)
        }
    }
}
