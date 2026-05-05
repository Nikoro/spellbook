import Foundation
import Testing
@testable import SpellbookKit

struct AtomicWrapperWriterTests {

    @Test func writesContentToPath() throws {
        let directory = try makeTempDir()
        defer { try? FileManager.default.removeItem(atPath: directory) }
        let writer = AtomicWrapperWriter()
        let path = directory + "/build"
        try writer.writeWrapper(content: "#!/bin/sh\necho hi\n", to: path)
        let read = try String(contentsOfFile: path, encoding: .utf8)
        #expect(read == "#!/bin/sh\necho hi\n")
    }

    @Test func writesExecutablePermissions() throws {
        let directory = try makeTempDir()
        defer { try? FileManager.default.removeItem(atPath: directory) }
        let writer = AtomicWrapperWriter()
        let path = directory + "/build"
        try writer.writeWrapper(content: "x", to: path)
        let attrs = try FileManager.default.attributesOfItem(atPath: path)
        let permissions = attrs[.posixPermissions] as? NSNumber
        #expect(permissions?.intValue == 0o755)
    }

    @Test func overwriteReplacesExistingFile() throws {
        let directory = try makeTempDir()
        defer { try? FileManager.default.removeItem(atPath: directory) }
        let writer = AtomicWrapperWriter()
        let path = directory + "/build"
        try writer.writeWrapper(content: "first", to: path)
        try writer.writeWrapper(content: "second", to: path)
        let read = try String(contentsOfFile: path, encoding: .utf8)
        #expect(read == "second")
    }

    @Test func writeDoesNotLeaveTempArtifact() throws {
        let directory = try makeTempDir()
        defer { try? FileManager.default.removeItem(atPath: directory) }
        let writer = AtomicWrapperWriter()
        let path = directory + "/build"
        try writer.writeWrapper(content: "x", to: path)
        #expect(!FileManager.default.fileExists(atPath: path + ".tmp"))
    }

    @Test func writeCreatesIntermediateDirectories() throws {
        let directory = try makeTempDir()
        defer { try? FileManager.default.removeItem(atPath: directory) }
        let writer = AtomicWrapperWriter()
        let path = directory + "/nested/deeper/build"
        try writer.writeWrapper(content: "x", to: path)
        #expect(FileManager.default.fileExists(atPath: path))
    }

    @Test func removeDeletesExistingWrapper() throws {
        let directory = try makeTempDir()
        defer { try? FileManager.default.removeItem(atPath: directory) }
        let writer = AtomicWrapperWriter()
        let path = directory + "/build"
        try writer.writeWrapper(content: "x", to: path)
        try writer.removeWrapper(at: path)
        #expect(!FileManager.default.fileExists(atPath: path))
    }

    @Test func removeOnMissingPathIsNoop() throws {
        let directory = try makeTempDir()
        defer { try? FileManager.default.removeItem(atPath: directory) }
        let writer = AtomicWrapperWriter()
        // Must not throw.
        try writer.removeWrapper(at: directory + "/missing")
    }

    private func makeTempDir() throws -> String {
        let path = NSTemporaryDirectory() + "spellbook-wrapper-\(UUID().uuidString)"
        try FileManager.default.createDirectory(
            atPath: path, withIntermediateDirectories: true
        )
        return path
    }
}
