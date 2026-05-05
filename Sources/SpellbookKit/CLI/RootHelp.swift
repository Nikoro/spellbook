enum RootHelp {
    static func render() -> String {
        """
        spells \(SpellbookVersion.current)

        Usage:
          spells                Activate the current project
          spells list           List available spells
          spells list --verbose List spells with details
          spells diff           Show changes since last activation
          spells clean <target> Remove wrapper(s): <name> | --all | --orphans
          spells doctor         Check for common issues
          spells doctor --fix   Re-activate to resolve state/wrapper drift
          spells create [name]  Create a new manifest
          spells init <shell>   Print shell integration (zsh, bash, fish)
          spells completion <shell>
                                Print completion script (zsh, bash, fish)
          spells --version      Show version
          spells --help         Show this help
        """
    }
}
