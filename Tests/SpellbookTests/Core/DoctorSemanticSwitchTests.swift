import Testing
@testable import SpellbookKit

struct DoctorSemanticSwitchTests {

    private let resolver = DoctorResolver()

    @Test func switchOption_unknownPlaceholderProducesWarning() {
        let option = SwitchOptionDefinition(
            name: "stg",
            command: SpellDefinition(name: "stg-cmd", script: "deploy {{missing}}")
        )
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(
                identity: SpellIdentity(name: "deploy"),
                body: SpellBody(switchBranches: SwitchDefinition(options: [option]))
            )
        ])
        let report = diagnose(manifest: manifest)
        let warnings = semanticWarnings(from: report)
            .filter { $0.message.contains("Unknown placeholder") }
        #expect(warnings.count == 1)
        #expect(warnings[0].message.contains("missing"))
    }

    @Test func nestedSwitch_unknownPlaceholderProducesWarning() {
        let leaf = SwitchOptionDefinition(
            name: "us-east",
            command: SpellDefinition(name: "us-east-cmd", script: "run {{ghost}}")
        )
        let inner = SwitchDefinition(options: [leaf])
        let outer = SwitchOptionDefinition(
            name: "stg",
            command: SpellDefinition(
                identity: SpellIdentity(name: "stg-cmd"),
                body: SpellBody(switchBranches: inner)
            )
        )
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(
                identity: SpellIdentity(name: "deploy"),
                body: SpellBody(switchBranches: SwitchDefinition(options: [outer]))
            )
        ])
        let report = diagnose(manifest: manifest)
        let warnings = semanticWarnings(from: report)
            .filter { $0.message.contains("ghost") }
        #expect(warnings.count == 1)
    }

    @Test func inlineDefaultBranch_scriptIsScannedForUnknownPlaceholders() {
        let option = SwitchOptionDefinition(
            name: "stg", command: SpellDefinition(name: "stg-cmd", script: "ok")
        )
        let inlineDefault = SpellDefinition(name: "fallback", script: "echo {{missing}}")
        let switchDef = SwitchDefinition(
            options: [option], defaultBranch: .inline(inlineDefault)
        )
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(
                identity: SpellIdentity(name: "deploy"),
                body: SpellBody(switchBranches: switchDef)
            )
        ])
        let report = diagnose(manifest: manifest)
        let warnings = semanticWarnings(from: report)
            .filter { $0.message.contains("missing") }
        #expect(warnings.count == 1)
    }

    @Test func keyDefaultBranch_isNotScanned() {
        let option = SwitchOptionDefinition(
            name: "stg", command: SpellDefinition(name: "stg-cmd", script: "ok")
        )
        let switchDef = SwitchDefinition(
            options: [option], defaultBranch: .key("stg")
        )
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(
                identity: SpellIdentity(name: "deploy"),
                body: SpellBody(switchBranches: switchDef)
            )
        ])
        let report = diagnose(manifest: manifest)
        #expect(semanticWarnings(from: report).isEmpty)
    }

    @Test func switchOption_unusedParamProducesWarning() {
        let option = SwitchOptionDefinition(
            name: "stg",
            command: SpellDefinition(name: "stg-cmd", script: "deploy without ref")
        )
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(
                identity: SpellIdentity(name: "deploy"),
                body: SpellBody(
                    params: [ParamDefinition(name: "tag")],
                    switchBranches: SwitchDefinition(options: [option])
                )
            )
        ])
        let report = diagnose(manifest: manifest)
        let warnings = semanticWarnings(from: report)
            .filter { $0.message.contains("Param `tag`") }
        #expect(warnings.count == 1)
    }

    // MARK: - Helpers

    private func diagnose(manifest: SpellbookManifest) -> DoctorReport {
        let result = ActivationResult(
            manifest: manifest,
            location: ManifestLocation(path: "/project/spells.yaml", source: .project),
            chain: ["/project/spells.yaml"]
        )
        return resolver.diagnose(DoctorInput(
            activationResult: result,
            activationError: nil,
            pathEnv: "/Users/me/.spellbook/bin",
            spellbookBinDir: "/Users/me/.spellbook/bin",
            stateSnapshot: nil
        ))
    }

    private func semanticWarnings(from report: DoctorReport) -> [DiagnosticItem] {
        report.items.filter { $0.category == .semantic }
    }
}
