import XCTest
@testable import SpellbookKit

final class FoundationPathBinaryCheckerTests: XCTestCase {
    func test_findsBinaryInPath() {
        let checker = FoundationPathBinaryChecker(
            pathEnv: "/usr/bin:/bin",
            spellbookBin: "/tmp/nope"
        )
        XCTAssertTrue(checker.isInPath("ls"))
    }

    func test_returnsFalseForMissingBinary() {
        let checker = FoundationPathBinaryChecker(
            pathEnv: "/usr/bin:/bin",
            spellbookBin: "/tmp/nope"
        )
        XCTAssertFalse(checker.isInPath("this-binary-does-not-exist-xyz"))
    }

    func test_skipsSpellbookBinDirectory() throws {
        let tmp = try createTmpBin(named: "fakecmd")
        defer { try? FileManager.default.removeItem(atPath: tmp) }
        let checker = FoundationPathBinaryChecker(
            pathEnv: tmp, spellbookBin: tmp
        )
        XCTAssertFalse(checker.isInPath("fakecmd"))
    }

    private func createTmpBin(named: String) throws -> String {
        let tmp = NSTemporaryDirectory() + "pbc-" + UUID().uuidString
        try FileManager.default.createDirectory(atPath: tmp, withIntermediateDirectories: true)
        let file = tmp + "/" + named
        FileManager.default.createFile(
            atPath: file, contents: Data("#!/bin/sh\n".utf8),
            attributes: [.posixPermissions: 0o755]
        )
        return tmp
    }
}
