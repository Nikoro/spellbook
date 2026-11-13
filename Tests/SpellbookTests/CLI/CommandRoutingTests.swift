import Foundation
import Testing
@testable import SpellbookKit

struct CommandRoutingTests {
    @Test func informationalCommandsUseThePublicExecutable() throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        #expect(try invoke(["--version"], in: directory).stdout.contains(SpellbookVersion.current))
        #expect(try invoke(["--help"], in: directory).stdout.contains("spells"))
        #expect(try invoke(["init", "zsh"], in: directory).stdout.contains("spellbook"))
        #expect(try invoke(["completion", "bash"], in: directory).stdout.contains("complete"))
        #expect(try invoke(["pick"], in: directory).exitCode == 0)
    }

    @Test func activationListingDiffAndCleanupKeepStateConsistent() throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try writeManifest(in: directory)
        #expect(try invoke([], in: directory).stdout.contains("Activated 1 spells"))
        #expect(try invoke(["list"], in: directory).stdout.contains("sbfixture"))
        #expect(try invoke(["diff"], in: directory).stdout.contains("No changes"))
        #expect(try invoke(["doctor"], in: directory).exitCode == 0)
        #expect(try invoke(["help", "sbfixture"], in: directory).stdout.contains("sbfixture"))
        #expect(try invoke(["clean", "--all"], in: directory).exitCode == 0)
        #expect(FileManager.default.fileExists(atPath: directory.path + "/home/bin/sbfixture") == false)
    }

    @Test func runAndCompletionReachTheManifestThroughRealAdapters() throws {
        let directory = try makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try writeManifest(in: directory)
        let execution = try invoke(["run", "sbfixture", "--cwd", directory.path, "--"], in: directory)
        #expect(execution.exitCode == 0)
        #expect(execution.stdout.contains("fixture-output"))
        let completion = try invoke(
            ["complete", "sbfixture", "--cword", "1", "--", "sbfixture", ""], in: directory
        )
        #expect(completion.exitCode == 0)
        #expect(completion.stdout.contains("runAsIs"))
    }

    private func makeDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.resolvingSymlinksInPath()
    }

    private func writeManifest(in directory: URL) throws {
        let source = "spells:\n  sbfixture:\n    script: echo fixture-output\n"
        try source.write(to: directory.appendingPathComponent("spells.yaml"), atomically: true, encoding: .utf8)
    }

    private func invoke(_ arguments: [String], in directory: URL) throws -> (exitCode: Int32, stdout: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent(".build/debug/spells")
        process.arguments = arguments
        process.environment = ProcessInfo.processInfo.environment.merging(
            [
                "SPELLBOOK_HOME": directory.path + "/home", "HOME": directory.path,
                "PATH": directory.path + "/home/bin:" + (ProcessInfo.processInfo.environment["PATH"] ?? "")
            ]
        ) { _, supplied in supplied }
        process.currentDirectoryURL = directory
        process.standardInput = FileHandle.nullDevice
        let output = Pipe()
        process.standardOutput = output
        try process.run()
        let bytes = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        let text = try #require(String(data: bytes, encoding: .utf8))
        return (exitCode: process.terminationStatus, stdout: text)
    }
}
