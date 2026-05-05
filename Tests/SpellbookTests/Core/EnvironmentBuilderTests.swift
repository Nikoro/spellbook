import Testing
@testable import SpellbookKit

struct EnvironmentBuilderTests {

    @Test func allKeysPresent() {
        let env = EnvironmentBuilder().build(.init(
            spellName: "deploy",
            projectRoot: "/project",
            manifestPath: "/project/spells.yaml",
            originPath: "/shared/spells.yaml",
            workingDir: "/project/src"
        ))

        #expect(env["SPELLBOOK_SPELL_NAME"] == "deploy")
        #expect(env["SPELLBOOK_PROJECT_ROOT"] == "/project")
        #expect(env["SPELLBOOK_MANIFEST_PATH"] == "/project/spells.yaml")
        #expect(env["SPELLBOOK_ORIGIN_PATH"] == "/shared/spells.yaml")
        #expect(env["SPELLBOOK_WORKING_DIR"] == "/project/src")
        #expect(env.count == 5)
    }

    @Test func noExtraKeys() {
        let env = EnvironmentBuilder().build(.init(
            spellName: "x",
            projectRoot: "/p",
            manifestPath: "/p/spells.yaml",
            originPath: "/p/spells.yaml",
            workingDir: "/p"
        ))

        let keys = Set(env.keys)
        let expected: Set<String> = [
            "SPELLBOOK_SPELL_NAME",
            "SPELLBOOK_PROJECT_ROOT",
            "SPELLBOOK_MANIFEST_PATH",
            "SPELLBOOK_ORIGIN_PATH",
            "SPELLBOOK_WORKING_DIR"
        ]
        #expect(keys == expected)
    }
}
