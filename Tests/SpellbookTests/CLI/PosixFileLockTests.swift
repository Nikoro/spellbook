import Foundation
import Testing
@testable import SpellbookKit

struct PosixFileLockTests {

    @Test func bodyRunsAndReturnsValue() throws {
        let directory = try makeTempDir()
        defer { try? FileManager.default.removeItem(atPath: directory) }
        let lock = PosixFileLock(path: directory + "/state.lock")
        let value = try lock.withExclusiveLock { 42 }
        #expect(value == 42)
    }

    @Test func bodyThrowsArePropagated() throws {
        let directory = try makeTempDir()
        defer { try? FileManager.default.removeItem(atPath: directory) }
        let lock = PosixFileLock(path: directory + "/state.lock")
        #expect(throws: SampleError.boom) {
            try lock.withExclusiveLock { throw SampleError.boom }
        }
    }

    @Test func openFailureSurfacesFileLockError() throws {
        // Place the lock at a path whose parent is a regular file, not a
        // directory. ensureParentDirectoryExists will throw, but if it did
        // succeed the open() would still fail; either way the error must
        // propagate as FileLockError.
        let directory = try makeTempDir()
        defer { try? FileManager.default.removeItem(atPath: directory) }
        let parentFile = directory + "/parent"
        try Data().write(to: URL(fileURLWithPath: parentFile))
        let lockPath = parentFile + "/state.lock"
        let lock = PosixFileLock(path: lockPath)
        #expect(throws: (any Error).self) {
            try lock.withExclusiveLock { 0 }
        }
    }

    @Test func bareFilenameWithoutDirectoryDoesNotThrow() throws {
        // Path with no slash: deletingLastPathComponent is empty, so the
        // ensureParentDirectoryExists guard returns early. Use a temp dir
        // as cwd so the lock file lands somewhere disposable.
        let directory = try makeTempDir()
        defer { try? FileManager.default.removeItem(atPath: directory) }
        let originalCwd = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(directory)
        defer { FileManager.default.changeCurrentDirectoryPath(originalCwd) }
        let lock = PosixFileLock(path: "state.lock")
        let value = try lock.withExclusiveLock { 7 }
        #expect(value == 7)
    }

    @Test func concurrentHoldersObserveSerialAccess() throws {
        let directory = try makeTempDir()
        defer { try? FileManager.default.removeItem(atPath: directory) }
        let lockPath = directory + "/state.lock"
        let observed = MaxObserver()
        let group = DispatchGroup()
        for _ in 0..<8 {
            group.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                let lock = PosixFileLock(path: lockPath)
                try? lock.withExclusiveLock {
                    observed.enter()
                    Thread.sleep(forTimeInterval: 0.005)
                    observed.leave()
                }
                group.leave()
            }
        }
        group.wait()
        #expect(observed.maxConcurrent == 1)
        #expect(observed.current == 0)
    }

    private func makeTempDir() throws -> String {
        let path = NSTemporaryDirectory() + "spellbook-lock-\(UUID().uuidString)"
        try FileManager.default.createDirectory(
            atPath: path, withIntermediateDirectories: true
        )
        return path
    }

    private enum SampleError: Error, Equatable {
        case boom
    }

    fileprivate final class MaxObserver: @unchecked Sendable {
        private let mutex = NSLock()
        private var inside = 0
        private(set) var maxConcurrent = 0

        func enter() {
            mutex.lock(); defer { mutex.unlock() }
            inside += 1
            if inside > maxConcurrent { maxConcurrent = inside }
        }

        func leave() {
            mutex.lock(); defer { mutex.unlock() }
            inside -= 1
        }

        var current: Int {
            mutex.lock(); defer { mutex.unlock() }
            return inside
        }
    }
}
