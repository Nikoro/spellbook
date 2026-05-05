import Testing
@testable import SpellbookKit

struct DoctorUnknownPlaceholderTests {

    private let resolver = DoctorResolver()

    @Test func unknownPlaceholder_producesWarning() {
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(name: "hello", script: "echo {{missing}}")
        ])
        let warnings = unknownWarnings(for: manifest)
        #expect(warnings.count == 1)
        #expect(warnings[0].message.contains("{{missing}}"))
        #expect(warnings[0].message.contains("hello"))
    }

    @Test func knownParamPlaceholder_noUnknownWarning() {
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(
                identity: SpellIdentity(name: "greet"),
                body: SpellBody(
                    script: "echo {{name}}",
                    params: [ParamDefinition(name: "name")]
                )
            )
        ])
        #expect(unknownWarnings(for: manifest).isEmpty)
    }

    @Test func overrideSelfPlaceholder_noUnknownWarning() {
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(
                identity: SpellIdentity(name: "git"),
                body: SpellBody(script: "{{git}} status"),
                runtime: SpellRuntime(override: true)
            )
        ])
        #expect(unknownWarnings(for: manifest).isEmpty)
    }

    @Test func templateSyntaxWithSpaces_notFlagged() {
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(name: "render", script: "echo {{ .Name }}")
        ])
        #expect(unknownWarnings(for: manifest).isEmpty)
    }

    @Test func unknownPlaceholderDeduplicated_perSpell() {
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(name: "hello", script: "echo {{missing}} and {{missing}}")
        ])
        #expect(unknownWarnings(for: manifest).count == 1)
    }

    @Test func warningIsAlwaysSeverityWarning() {
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(name: "hello", script: "echo {{missing}}")
        ])
        for warning in unknownWarnings(for: manifest) {
            #expect(warning.severity == .warning)
        }
    }

    private func unknownWarnings(for manifest: SpellbookManifest) -> [DiagnosticItem] {
        let result = ActivationResult(
            manifest: manifest,
            location: ManifestLocation(path: "/project/spells.yaml", source: .project),
            chain: ["/project/spells.yaml"]
        )
        let report = resolver.diagnose(DoctorInput(
            activationResult: result,
            activationError: nil,
            pathEnv: "/bin",
            spellbookBinDir: "/bin",
            stateSnapshot: nil,
            pathChecker: nil
        ))
        return report.items.filter { $0.message.contains("Unknown placeholder") }
    }
}
