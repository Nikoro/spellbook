import Testing
@testable import SpellbookKit

struct OverrideValidationEdgeTests {

    // MARK: - Shell-state builtin edge cases

    @Test func aliasIsBuiltin_withOverride_isStillRejected() {
        let checker = MockPathBinaryChecker(binaries: [])
        let validator = SpellbookValidator(pathChecker: checker)
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(
                identity: SpellIdentity(name: "myspell", aliases: ["source"]),
                body: SpellBody(script: "./run"),
                runtime: SpellRuntime(override: true)
            )
        ])
        #expect(validator.validate(manifest) == [.aliasIsShellStateBuiltin(spell: "myspell", alias: "source")])
    }

    @Test func multipleAliases_someBuiltin_reportsEachOne() {
        let checker = MockPathBinaryChecker(binaries: [])
        let validator = SpellbookValidator(pathChecker: checker)
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(
                identity: SpellIdentity(
                    name: "myspell",
                    aliases: ["ok", "cd", "fine", "eval"]
                ),
                body: SpellBody(script: "./run")
            )
        ])
        let errors = validator.validate(manifest)
        #expect(errors.contains(.aliasIsShellStateBuiltin(spell: "myspell", alias: "cd")))
        #expect(errors.contains(.aliasIsShellStateBuiltin(spell: "myspell", alias: "eval")))
        #expect(errors.count == 2)
    }

    // MARK: - Free names

    @Test func freeNameWithOverride_isValid() {
        let checker = MockPathBinaryChecker(binaries: ["git"])
        let validator = SpellbookValidator(pathChecker: checker)
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(
                identity: SpellIdentity(name: "deploy"),
                body: SpellBody(script: "./deploy"),
                runtime: SpellRuntime(override: true)
            )
        ])
        #expect(validator.validate(manifest) == [])
    }

    // MARK: - Path shadow + alias combinations

    @Test func multipleAliases_oneShadowsPath_reportsOnlyThat() {
        let checker = MockPathBinaryChecker(binaries: ["ls"])
        let validator = SpellbookValidator(pathChecker: checker)
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(
                identity: SpellIdentity(name: "list", aliases: ["l", "ls", "la"]),
                body: SpellBody(script: "./list"),
                runtime: SpellRuntime(override: true)
            )
        ])
        #expect(validator.validate(manifest) == [.aliasShadowsPathBinary(spell: "list", alias: "ls")])
    }

    @Test func spellAndAlias_bothInPath_overrideCoversSpellOnly() {
        let checker = MockPathBinaryChecker(binaries: ["git", "g"])
        let validator = SpellbookValidator(pathChecker: checker)
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(
                identity: SpellIdentity(name: "git", aliases: ["g"]),
                body: SpellBody(script: "{{git}} ...args"),
                runtime: SpellRuntime(override: true)
            )
        ])
        let errors = validator.validate(manifest)
        #expect(errors.contains(.spellShadowsPathBinary(spell: "git")) == false)
        #expect(errors == [.aliasShadowsPathBinary(spell: "git", alias: "g")])
    }

    @Test func spellAndAlias_bothInPath_noOverride_reportsBoth() {
        let checker = MockPathBinaryChecker(binaries: ["git", "g"])
        let validator = SpellbookValidator(pathChecker: checker)
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(
                identity: SpellIdentity(name: "git", aliases: ["g"]),
                body: SpellBody(script: "./git")
            )
        ])
        let errors = validator.validate(manifest)
        #expect(errors.contains(.spellShadowsPathBinary(spell: "git")))
        #expect(errors.contains(.aliasShadowsPathBinary(spell: "git", alias: "g")))
    }

    // MARK: - Builtin precedence over path shadow

    @Test func spellIsBuiltin_alsoInPath_reportsOnlyBuiltinError() {
        let checker = MockPathBinaryChecker(binaries: ["eval"])
        let validator = SpellbookValidator(pathChecker: checker)
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(
                identity: SpellIdentity(name: "eval"),
                body: SpellBody(script: "./eval"),
                runtime: SpellRuntime(override: true)
            )
        ])
        let errors = validator.validate(manifest)
        #expect(errors == [.spellIsShellStateBuiltin(spell: "eval")])
    }

    @Test func aliasIsBuiltin_alsoInPath_reportsOnlyBuiltinError() {
        let checker = MockPathBinaryChecker(binaries: ["cd"])
        let validator = SpellbookValidator(pathChecker: checker)
        let manifest = SpellbookManifest(spells: [
            SpellDefinition(
                identity: SpellIdentity(name: "jump", aliases: ["cd"]),
                body: SpellBody(script: "./jump")
            )
        ])
        let errors = validator.validate(manifest)
        #expect(errors.contains(.aliasIsShellStateBuiltin(spell: "jump", alias: "cd")))
        #expect(errors.contains(.aliasShadowsPathBinary(spell: "jump", alias: "cd")) == false)
    }

    // MARK: - Param shadows override spell name

    @Test func overrideSpell_hyphenatedName_underscoreParam_noCollision() {
        let spell = SpellDefinition(
            identity: SpellIdentity(name: "my-tool"),
            body: SpellBody(
                script: "{{my-tool}} --flag",
                params: [ParamDefinition(name: "my_tool")]
            ),
            runtime: SpellRuntime(override: true)
        )
        let errors = SpellbookValidator().validate(
            SpellbookManifest(spells: [spell])
        )
        #expect(errors.contains(where: {
            if case .paramShadowsOverriddenSpell = $0 { return true }
            return false
        }) == false)
    }

    @Test func overrideSpell_multipleParams_oneShadows_isError() {
        let spell = SpellDefinition(
            identity: SpellIdentity(name: "grep"),
            body: SpellBody(
                script: "{{grep}} {{pattern}}",
                params: [
                    ParamDefinition(name: "pattern"),
                    ParamDefinition(name: "grep")
                ]
            ),
            runtime: SpellRuntime(override: true)
        )
        let errors = SpellbookValidator().validate(
            SpellbookManifest(spells: [spell])
        )
        #expect(errors.contains(
            .paramShadowsOverriddenSpell(spell: "grep", param: "grep")
        ))
    }
}
