import CryptoKit
import Foundation

public enum ManifestHasher {
    public static func hashManifest(_ content: String) -> String {
        sha256(content)
    }

    public static func hashSpell(_ spell: SpellDefinition) -> String {
        sha256(normalizedSpell(spell))
    }

    private static func normalizedSpell(_ spell: SpellDefinition) -> String {
        var parts: [String] = ["name:\(spell.name)"]
        if let desc = spell.description { parts.append("desc:\(desc)") }
        parts += spell.aliases.map { "alias:\($0)" }
        if let script = spell.script { parts.append("script:\(script)") }
        parts += spell.params.map { "param:\($0.name)" }
        parts.append("override:\(spell.override)")
        parts.append("silent:\(spell.silent)")
        if let workingDir = spell.workingDir { parts.append("wd:\(workingDir)") }
        if let shell = spell.shell { parts.append("shell:\(shell)") }
        return parts.joined(separator: "\n")
    }

    private static func sha256(_ input: String) -> String {
        let digest = SHA256.hash(data: Data(input.utf8))
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        return "sha256:\(hex)"
    }
}
