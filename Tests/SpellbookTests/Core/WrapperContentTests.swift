import Testing
@testable import SpellbookKit

struct WrapperContentTests {

    @Test func render_producesShebangAndExecLine() {
        let content = WrapperContent.render(spellName: "hello")
        let lines = content.components(separatedBy: "\n")
        #expect(lines.count == 2)
        #expect(lines[0] == "#!/bin/sh")
        #expect(lines[1] == "exec spells run \"hello\" --cwd \"$PWD\" -- \"$@\"")
    }

    @Test func render_quotesSpellNameWithSpaces() {
        let content = WrapperContent.render(spellName: "my-spell")
        #expect(content.contains("\"my-spell\""))
    }

    @Test func aliasWrapper_dispatchesToCanonicalName() {
        let content = WrapperContent.render(spellName: "test")
        #expect(content.components(separatedBy: "\n")[1] == "exec spells run \"test\" --cwd \"$PWD\" -- \"$@\"")
    }
}
