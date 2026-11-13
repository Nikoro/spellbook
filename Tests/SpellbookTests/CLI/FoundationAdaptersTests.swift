import Foundation
import Testing
@testable import SpellbookKit

struct FoundationAdaptersTests {
    @Test func fileAdaptersPreserveUTF8AndReportMissingFiles() throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let path = directory.appendingPathComponent("spells.yaml").path
        let content = "spells:\n  hello:\n    description: Zażółć\n    script: echo hello\n"
        try FoundationFileWriter().writeFile(content: content, to: path)
        #expect(FoundationFileSystem().probe(path) == .present)
        #expect(FoundationFileSystem().probe(path + ".missing") == .missing)
        #expect(try FoundationManifestContentReader().readContent(at: path) == content)
        let manifest = try FoundationManifestReader().read(at: path)
        #expect(manifest.spells.first?.name == "hello")
    }

    @Test func manifestLoaderResolvesRelativeParentAndRejectsMissingParent() throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let parent = directory.appendingPathComponent("spells.yaml")
        try "spells:\n  hello: echo hi\n".write(to: parent, atomically: true, encoding: .utf8)
        let loader = FoundationManifestLoader(fileSystem: FoundationFileSystem())
        let child = directory.appendingPathComponent("child/spells.yaml").path
        let loaded = try loader.load(extends: "..", from: child)
        #expect(loaded.canonicalPath == parent.path)
        #expect(loaded.manifest.spells.first?.name == "hello")
        #expect(throws: SpellbookError.self) {
            try loader.load(extends: "absent", from: child)
        }
    }

    @Test func capturingRunnerPreservesStreamsEnvironmentAndExitCode() throws {
        let invocation = ProcessInvocation(
            executablePath: "/bin/sh",
            arguments: ["-c", "printf '%s' \"$SPELLBOOK_ADAPTER_TEST\"; printf 'problem' >&2; exit 7"],
            environment: ["SPELLBOOK_ADAPTER_TEST": "hello"]
        )
        let result = try FoundationCapturingRunner().runCapturing(
            invocation: invocation, bufferCap: 1024, overflowHandler: { _, _ in }
        )
        #expect(result.exitCode == 7)
        #expect(String(bytes: result.stdout, encoding: .utf8) == "hello")
        #expect(String(bytes: result.stderr, encoding: .utf8) == "problem")
        #expect(!result.didOverflow)
    }

    @Test func capturingRunnerReportsLaunchFailure() {
        let invocation = ProcessInvocation(executablePath: "/not/a/real/executable", arguments: [])
        #expect(throws: SpellbookError.self) {
            try FoundationCapturingRunner().runCapturing(
                invocation: invocation, bufferCap: 1024, overflowHandler: { _, _ in }
            )
        }
    }

    private func makeDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.resolvingSymlinksInPath()
    }
}
