import Testing
@testable import SpellbookKit

struct SpellbookVersionTests {
    @Test func current_isNotEmpty() {
        #expect(SpellbookVersion.current.isEmpty == false)
    }

    @Test func current_looksLikeSemver() throws {
        let parts = SpellbookVersion.current.split(separator: "-")[0].split(separator: ".")
        #expect(parts.count == 3, "expected major.minor.patch in \(SpellbookVersion.current)")
        for part in parts {
            #expect(Int(part) != nil, "non-numeric semver component: \(part)")
        }
    }
}
