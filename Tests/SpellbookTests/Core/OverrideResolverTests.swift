import Testing
@testable import SpellbookKit

struct OverrideResolverTests {

    // MARK: - PATH walk order

    @Test func findsFirstMatchInPathOrder() {
        let fileSystem = MockFileSystem()
        fileSystem.files = ["/usr/local/bin/git", "/usr/bin/git"]
        let resolver = OverrideResolver(
            pathDirectories: ["/usr/local/bin", "/usr/bin"],
            spellbookBin: "/Users/me/.spellbook/bin",
            fileSystem: fileSystem
        )

        #expect(resolver.externalCommand(for: "git") == "/usr/local/bin/git")
    }

    @Test func returnsSecondMatch_whenFirstDirectoryMissesBinary() {
        let fileSystem = MockFileSystem()
        fileSystem.files = ["/usr/bin/git"]
        let resolver = OverrideResolver(
            pathDirectories: ["/usr/local/bin", "/usr/bin"],
            spellbookBin: "/Users/me/.spellbook/bin",
            fileSystem: fileSystem
        )

        #expect(resolver.externalCommand(for: "git") == "/usr/bin/git")
    }

    // MARK: - Spellbook bin exclusion

    @Test func skipsSpellbookBinDirectory() {
        let fileSystem = MockFileSystem()
        fileSystem.files = ["/Users/me/.spellbook/bin/git", "/usr/bin/git"]
        let resolver = OverrideResolver(
            pathDirectories: ["/Users/me/.spellbook/bin", "/usr/bin"],
            spellbookBin: "/Users/me/.spellbook/bin",
            fileSystem: fileSystem
        )

        #expect(resolver.externalCommand(for: "git") == "/usr/bin/git")
    }

    @Test func skipsSpellbookBinWithTrailingSlash() {
        let fileSystem = MockFileSystem()
        fileSystem.files = ["/Users/me/.spellbook/bin/git", "/usr/bin/git"]
        let resolver = OverrideResolver(
            pathDirectories: ["/Users/me/.spellbook/bin/", "/usr/bin"],
            spellbookBin: "/Users/me/.spellbook/bin",
            fileSystem: fileSystem
        )

        #expect(resolver.externalCommand(for: "git") == "/usr/bin/git")
    }

    // MARK: - Missing external command

    @Test func returnsNil_whenNoExternalCommandFound() {
        let fileSystem = MockFileSystem()
        let resolver = OverrideResolver(
            pathDirectories: ["/usr/local/bin", "/usr/bin"],
            spellbookBin: "/Users/me/.spellbook/bin",
            fileSystem: fileSystem
        )

        #expect(resolver.externalCommand(for: "nonexistent") == nil)
    }

    @Test func returnsNil_whenOnlySpellbookBinHasBinary() {
        let fileSystem = MockFileSystem()
        fileSystem.files = ["/Users/me/.spellbook/bin/mytool"]
        let resolver = OverrideResolver(
            pathDirectories: ["/Users/me/.spellbook/bin", "/usr/bin"],
            spellbookBin: "/Users/me/.spellbook/bin",
            fileSystem: fileSystem
        )

        #expect(resolver.externalCommand(for: "mytool") == nil)
    }

    // MARK: - Denied entries

    @Test func skipsDeniedEntries() {
        let fileSystem = MockFileSystem()
        fileSystem.deniedPaths = ["/restricted/bin/git"]
        fileSystem.files = ["/usr/bin/git"]
        let resolver = OverrideResolver(
            pathDirectories: ["/restricted/bin", "/usr/bin"],
            spellbookBin: "/Users/me/.spellbook/bin",
            fileSystem: fileSystem
        )

        #expect(resolver.externalCommand(for: "git") == "/usr/bin/git")
    }

    // MARK: - Empty PATH

    @Test func emptyPathDirectories_returnsNil() {
        let fileSystem = MockFileSystem()
        let resolver = OverrideResolver(
            pathDirectories: [],
            spellbookBin: "/Users/me/.spellbook/bin",
            fileSystem: fileSystem
        )

        #expect(resolver.externalCommand(for: "git") == nil)
    }
}
