import Testing
@testable import SpellbookKit

struct SpellbookValidatorPathTests {
    @Test func spellWithoutOverride_shadowingPath_isError() {
        let checker = MockPathBinaryChecker(binaries: ["git"])
        let validator = SpellbookValidator(pathChecker: checker)
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(name: "git", script: "./git")
        ])
        #expect(validator.validate(manifest) == [.spellShadowsPathBinary(spell: "git")])
    }

    @Test func spellWithOverride_shadowingPath_isValid() {
        let checker = MockPathBinaryChecker(binaries: ["git"])
        let validator = SpellbookValidator(pathChecker: checker)
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(
                identity: SpellIdentity(name: "git"),
                body: SpellBody(script: "./git"),
                runtime: SpellRuntime(override: true)
            )
        ])
        #expect(validator.validate(manifest) == [])
    }

    @Test func alias_shadowingPath_isErrorEvenWithOverride() {
        let checker = MockPathBinaryChecker(binaries: ["ls"])
        let validator = SpellbookValidator(pathChecker: checker)
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(
                identity: SpellIdentity(name: "list", aliases: ["ls"]),
                body: SpellBody(script: "./list"),
                runtime: SpellRuntime(override: true)
            )
        ])
        #expect(validator.validate(manifest) == [.aliasShadowsPathBinary(spell: "list", alias: "ls")])
    }

    @Test func noPathChecker_skipsPathRules() {
        let validator = SpellbookValidator()
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(name: "git", script: "./git")
        ])
        #expect(validator.validate(manifest) == [])
    }

    @Test func spellWithoutOverride_notInPath_isValid() {
        let checker = MockPathBinaryChecker(binaries: [])
        let validator = SpellbookValidator(pathChecker: checker)
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(name: "deploy", script: "./deploy")
        ])
        #expect(validator.validate(manifest) == [])
    }

    @Test func alias_notInPath_isValid() {
        let checker = MockPathBinaryChecker(binaries: ["git"])
        let validator = SpellbookValidator(pathChecker: checker)
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(
                identity: SpellIdentity(name: "deploy", aliases: ["d", "dep"]),
                body: SpellBody(script: "./deploy")
            )
        ])
        #expect(validator.validate(manifest) == [])
    }

    // MARK: - Shell-state denylist

    @Test func spellOnDenylist_isRejected() {
        let checker = MockPathBinaryChecker(binaries: [])
        let validator = SpellbookValidator(pathChecker: checker)
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(name: "cd", script: "./cd")
        ])
        #expect(validator.validate(manifest) == [.spellIsShellStateBuiltin(spell: "cd")])
    }

    @Test func spellOnDenylist_withOverride_isStillRejected() {
        let checker = MockPathBinaryChecker(binaries: [])
        let validator = SpellbookValidator(pathChecker: checker)
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(
                identity: SpellIdentity(name: "export"),
                body: SpellBody(script: "./export"),
                runtime: SpellRuntime(override: true)
            )
        ])
        #expect(validator.validate(manifest) == [.spellIsShellStateBuiltin(spell: "export")])
    }

    @Test func aliasOnDenylist_isRejected() {
        let checker = MockPathBinaryChecker(binaries: [])
        let validator = SpellbookValidator(pathChecker: checker)
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(
                identity: SpellIdentity(name: "myalias", aliases: ["eval"]),
                body: SpellBody(script: "./myalias")
            )
        ])
        #expect(validator.validate(manifest) == [.aliasIsShellStateBuiltin(spell: "myalias", alias: "eval")])
    }

    @Test func denylistedSpell_doesNotProducePathShadowError() {
        let checker = MockPathBinaryChecker(binaries: ["cd"])
        let validator = SpellbookValidator(pathChecker: checker)
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(name: "cd", script: "./cd")
        ])
        let errors = validator.validate(manifest)
        #expect(errors == [.spellIsShellStateBuiltin(spell: "cd")])
        #expect(errors.contains(.spellShadowsPathBinary(spell: "cd")) == false)
    }
}
