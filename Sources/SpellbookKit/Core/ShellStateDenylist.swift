enum ShellStateDenylist {
    private static let entries: Set<String> = [
        "cd", "alias", "unalias", "export", "set", "unset",
        "source", ".", "exec", "readonly", "shift", "return",
        "eval", "trap", "ulimit", "umask", "wait", "jobs",
        "fg", "bg", "disown", "hash", "type", "builtin",
        "command", "local", "declare", "typeset", "pushd",
        "popd", "dirs", "suspend", "times", "caller",
        "logout", "enable", "help", "let", "mapfile",
        "readarray", "read"
    ]

    static func contains(_ name: String) -> Bool {
        entries.contains(name)
    }
}
