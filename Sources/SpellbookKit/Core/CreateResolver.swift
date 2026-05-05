public enum CreateResolver {
    public static func manifestContent(spellName: String? = nil) throws -> String {
        let name = spellName ?? "hello"
        if !SpellName.isValid(name) {
            throw SpellbookError.createInvalidName(name: name)
        }
        return """
        spells:
          \(name):
            script: echo "Hello from Spellbook"

        """
    }

    public static func targetPath(cwd: String) -> String {
        if cwd.hasSuffix("/") { return cwd + "spells.yaml" }
        return cwd + "/spells.yaml"
    }
}
