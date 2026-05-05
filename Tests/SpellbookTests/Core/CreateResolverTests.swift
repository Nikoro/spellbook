import Testing
@testable import SpellbookKit

struct CreateResolverTests {

    @Test func defaultName_producesHelloSpell() throws {
        let content = try CreateResolver.manifestContent()
        #expect(content.contains("hello:"))
        #expect(content.contains("script: echo"))
    }

    @Test func customValidName_producesNamedSpell() throws {
        let content = try CreateResolver.manifestContent(spellName: "build")
        #expect(content.contains("build:"))
        #expect(content.contains("hello:") == false)
    }

    @Test func invalidName_throwsError() {
        #expect(throws: SpellbookError.createInvalidName(name: "123bad")) {
            try CreateResolver.manifestContent(spellName: "123bad")
        }
    }

    @Test func canonicalYamlFormat() throws {
        let content = try CreateResolver.manifestContent()
        #expect(content.hasPrefix("spells:"))
    }

    @Test func targetPath_appendsSpellsYaml() {
        #expect(CreateResolver.targetPath(cwd: "/project") == "/project/spells.yaml")
    }

    @Test func targetPath_handlesTrailingSlash() {
        #expect(CreateResolver.targetPath(cwd: "/project/") == "/project/spells.yaml")
    }
}
