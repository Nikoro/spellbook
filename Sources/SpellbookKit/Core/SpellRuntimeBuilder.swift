struct SpellRuntimeBuilder {
    var override = false
    var silent = false
    var workingDir: String?
    var shell: String?

    mutating func absorb(_ field: MapEntry) {
        switch field.key {
        case "override": override = field.value.scalar == "true"
        case "silent": silent = field.value.scalar == "true"
        case "working_dir": workingDir = field.value.scalar
        case "shell": shell = field.value.scalar
        default: break
        }
    }

    func build() -> SpellRuntime {
        SpellRuntime(override: override, silent: silent, workingDir: workingDir, shell: shell)
    }
}
