public enum ShellIntegrationScripts {
    public enum Shell: String {
        case zsh, bash, fish
    }

    public static let integrationVersion = 1

    public static func script(for shell: Shell) -> String {
        switch shell {
        case .zsh: return ZshIntegrationScript.content
        case .bash: return BashIntegrationScript.content
        case .fish: return FishIntegrationScript.content
        }
    }
}
