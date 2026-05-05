import Foundation

enum DefaultPathChecker {
    static func make(spellbookHome: String) -> FoundationPathBinaryChecker {
        FoundationPathBinaryChecker(
            pathEnv: ProcessInfo.processInfo.environment["PATH"] ?? "",
            spellbookBin: spellbookHome + "/bin"
        )
    }
}
