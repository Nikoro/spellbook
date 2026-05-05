import Testing
@testable import SpellbookKit

struct SpellbookValidatorNameTests {
    private let validator = SpellbookValidator()

    @Test func spellName_withLeadingDigit_isError() {
        assertSpellName("1deploy", produces: .invalidSpellName(name: "1deploy"))
    }

    @Test func spellName_withDot_isError() {
        assertSpellName("deploy.prod", produces: .invalidSpellName(name: "deploy.prod"))
    }

    @Test func spellName_withSpace_isError() {
        assertSpellName("deploy prod", produces: .invalidSpellName(name: "deploy prod"))
    }

    @Test func spellName_withHyphen_isValid() {
        assertSpellName("git-status", produces: nil)
    }

    @Test func spellName_withUnderscore_isValid() {
        assertSpellName("run_tests", produces: nil)
    }

    @Test func spellName_empty_isError() {
        assertSpellName("", produces: .invalidSpellName(name: ""))
    }

    @Test func topLevel_duplicateSpellName_isError() {
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(name: "build", script: "./first"),
            SpellDefinition(name: "build", script: "./second")
        ])
        #expect(validator.validate(manifest) == [.duplicateSpellName(name: "build")])
    }

    @Test func topLevel_aliasCollidesWithSpellName_isError() {
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(
                identity: SpellIdentity(name: "build"),
                body: SpellBody(script: "./build")
            ),
            SpellDefinition(
                identity: SpellIdentity(name: "compile", aliases: ["build"]),
                body: SpellBody(script: "./compile")
            )
        ])
        #expect(validator.validate(manifest) == [.duplicateSpellName(name: "build")])
    }

    private func assertSpellName(
        _ name: String,
        produces expected: SpellbookError?,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(name: name, script: "./noop")
        ])
        let errors = validator.validate(manifest)
        if let expected {
            #expect(errors == [expected], sourceLocation: sourceLocation)
        } else {
            #expect(errors == [], sourceLocation: sourceLocation)
        }
    }
}
