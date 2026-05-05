import Testing
@testable import SpellbookKit

struct DoctorSemanticTests {

    private let resolver = DoctorResolver()
    private let binDir = "/Users/me/.spellbook/bin"

    // MARK: - Path shadowing

    @Test func spellShadowsPath_producesWarning() {
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(name: "git", script: "echo")
        ])
        let report = diagnose(manifest: manifest, binaries: ["git"])
        let warnings = semanticWarnings(from: report)
        #expect(warnings.count == 1)
        #expect(warnings[0].severity == .warning)
        #expect(warnings[0].message.contains("git"))
    }

    @Test func overrideSpell_noShadowWarning() {
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(
                identity: SpellIdentity(name: "git"),
                body: SpellBody(script: "{{git}} status"),
                runtime: SpellRuntime(override: true)
            )
        ])
        let report = diagnose(manifest: manifest, binaries: ["git"])
        let shadowWarnings = semanticWarnings(from: report).filter { $0.message.contains("Shadowing") }
        #expect(shadowWarnings.isEmpty)
    }

    // MARK: - Override without placeholder

    @Test func overrideWithoutPlaceholder_producesWarning() {
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(
                identity: SpellIdentity(name: "git"),
                body: SpellBody(script: "echo no placeholder"),
                runtime: SpellRuntime(override: true)
            )
        ])
        let report = diagnose(manifest: manifest, binaries: ["git"])
        let warnings = semanticWarnings(from: report).filter { $0.message.contains("Override") }
        #expect(warnings.count == 1)
        #expect(warnings[0].message.contains("{{git}}"))
    }

    @Test func overrideWithPlaceholder_noWarning() {
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(
                identity: SpellIdentity(name: "git"),
                body: SpellBody(script: "{{git}} status --short"),
                runtime: SpellRuntime(override: true)
            )
        ])
        let report = diagnose(manifest: manifest, binaries: ["git"])
        let overrideWarnings = semanticWarnings(from: report).filter { $0.message.contains("Override") }
        #expect(overrideWarnings.isEmpty)
    }

    // MARK: - Unused params

    @Test func unusedParam_producesWarning() {
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(
                identity: SpellIdentity(name: "greet"),
                body: SpellBody(
                    script: "echo hello",
                    params: [ParamDefinition(name: "name")]
                )
            )
        ])
        let report = diagnose(manifest: manifest)
        let paramWarnings = semanticWarnings(from: report).filter { $0.message.contains("Param") }
        #expect(paramWarnings.count == 1)
        #expect(paramWarnings[0].message.contains("name"))
        #expect(paramWarnings[0].message.contains("{{name}}"))
    }

    @Test func usedParam_noWarning() {
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(
                identity: SpellIdentity(name: "greet"),
                body: SpellBody(
                    script: "echo {{name}}",
                    params: [ParamDefinition(name: "name")]
                )
            )
        ])
        let report = diagnose(manifest: manifest)
        let paramWarnings = semanticWarnings(from: report).filter { $0.message.contains("Param") }
        #expect(paramWarnings.isEmpty)
    }

    // MARK: - Case collisions

    @Test func caseCollision_producesWarning() {
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(name: "Build", script: "make"),
            SpellDefinition(name: "build", script: "make")
        ])
        let report = diagnose(manifest: manifest)
        let caseWarnings = semanticWarnings(from: report).filter { $0.message.contains("Case collision") }
        #expect(caseWarnings.count == 1)
    }

    @Test func aliasCollisionWithName_producesWarning() {
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(name: "test", script: "swift test"),
            SpellDefinition(
                identity: SpellIdentity(name: "check", aliases: ["Test"]),
                body: SpellBody(script: "swift test")
            )
        ])
        let report = diagnose(manifest: manifest)
        let caseWarnings = semanticWarnings(from: report).filter { $0.message.contains("Case collision") }
        #expect(caseWarnings.count == 1)
    }

    @Test func noCaseCollision_noWarning() {
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(name: "build", script: "make"),
            SpellDefinition(name: "test", script: "swift test")
        ])
        let report = diagnose(manifest: manifest)
        let caseWarnings = semanticWarnings(from: report).filter { $0.message.contains("Case collision") }
        #expect(caseWarnings.isEmpty)
    }

    // MARK: - All semantic issues are warnings

    @Test func semanticIssuesAreAlwaysWarnings() {
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(name: "git", script: "echo"),
            SpellDefinition(
                identity: SpellIdentity(name: "curl"),
                body: SpellBody(script: "echo no placeholder"),
                runtime: SpellRuntime(override: true)
            )
        ])
        let report = diagnose(manifest: manifest, binaries: ["git", "curl"])
        let semantics = semanticWarnings(from: report)
        for item in semantics {
            #expect(item.severity == .warning, "Expected warning but got \(item.severity) for: \(item.message)")
        }
    }

    // MARK: - Helpers

    private func diagnose(
        manifest: SpellbookManifest,
        binaries: Set<String> = []
    ) -> DoctorReport {
        let result = ActivationResult(
            manifest: manifest,
            location: ManifestLocation(
                path: "/project/spells.yaml", source: .project
            ),
            chain: ["/project/spells.yaml"]
        )
        let checker: PathBinaryChecker? = binaries.isEmpty
            ? nil : MockPathBinaryChecker(binaries: binaries)
        return resolver.diagnose(DoctorInput(
            activationResult: result,
            activationError: nil,
            pathEnv: binDir,
            spellbookBinDir: binDir,
            stateSnapshot: nil,
            pathChecker: checker
        ))
    }

    private func semanticWarnings(from report: DoctorReport) -> [DiagnosticItem] {
        report.items.filter { $0.category == .semantic }
    }
}
