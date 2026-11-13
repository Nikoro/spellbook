import Darwin
import Foundation
import Testing

struct FoundationProcessRunnerTests {
    @Test func interactiveChildRemainsForegroundProcess() throws {
        let fixture = try makeFixture()
        defer { try? FileManager.default.removeItem(at: fixture) }
        let executable = spellsExecutablePath()
        try #require(FileManager.default.isExecutableFile(atPath: executable))
        let arguments = makeArguments(executable: executable, fixture: fixture.path)
        defer {
            for case let argument? in arguments {
                free(argument)
            }
        }
        var ptyDescriptor: Int32 = -1
        let child = forkpty(&ptyDescriptor, nil, nil, nil)

        try #require(child >= 0)
        if child == 0 {
            execute(executable: executable, arguments: arguments)
        }

        var status: Int32 = 0
        #expect(waitpid(child, &status, 0) == child)
        _ = close(ptyDescriptor)
        #expect(status == 0)
    }

    private func makeFixture() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let manifest = """
        spells:
          sb-e2e-foreground-probe:
            script: child=$(ps -o pgid= -p $$); foreground=$(ps -o tpgid= -p $$); test "$child" -eq "$foreground"
        """
        try manifest.write(to: directory.appendingPathComponent("spells.yaml"), atomically: true, encoding: .utf8)
        return directory
    }

    private func spellsExecutablePath() -> String {
        URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent(".build/debug")
            .appendingPathComponent("spells")
            .path
    }

    private func makeArguments(executable: String, fixture: String) -> [UnsafeMutablePointer<CChar>?] {
        let values = [executable, "run", "sb-e2e-foreground-probe", "--cwd", fixture, "--"]
        return values.map { value in value.withCString { strdup($0) } } + [nil]
    }

    private func execute(
        executable: String,
        arguments: [UnsafeMutablePointer<CChar>?]
    ) -> Never {
        _ = arguments.withUnsafeBufferPointer { buffer in
            execv(executable, UnsafeMutablePointer(mutating: buffer.baseAddress))
        }
        _exit(127)
    }
}
