import Testing
@testable import SpellbookKit

struct DirectoryWalkerTests {
    private let filesystem: MockFileSystem
    private var walker: DirectoryWalker

    init() {
        let fileSystem = MockFileSystem()
        self.filesystem = fileSystem
        self.walker = DirectoryWalker(fileSystem: fileSystem, home: "/home/user")
    }

    @Test func findsManifestInCurrentDirectory() throws {
        filesystem.files = ["/root/proj/spells.yaml"]
        let location = try walker.findManifest(startingAt: "/root/proj")
        #expect(location == ManifestLocation(path: "/root/proj/spells.yaml", source: .project))
    }

    @Test func walksUpUntilManifestFound() throws {
        filesystem.files = ["/root/spells.yaml"]
        let location = try walker.findManifest(startingAt: "/root/a/b/c")
        #expect(location?.path == "/root/spells.yaml")
    }

    @Test func prefersVisibleOverHiddenAndReportsShadow() throws {
        filesystem.files = ["/p/spells.yaml", "/p/.spells.yaml"]
        let location = try walker.findManifest(startingAt: "/p")
        #expect(location?.path == "/p/spells.yaml")
        #expect(location?.shadowsHidden == true)
    }

    @Test func usesHiddenManifestWhenNoVisibleExists() throws {
        filesystem.files = ["/p/.spells.yaml"]
        let location = try walker.findManifest(startingAt: "/p")
        #expect(location?.path == "/p/.spells.yaml")
    }

    @Test func fallsBackToHomeManifestWhenWalkFindsNothing() throws {
        filesystem.files = ["/home/user/spells.yaml"]
        let location = try walker.findManifest(startingAt: "/tmp/work")
        #expect(location == ManifestLocation(path: "/home/user/spells.yaml", source: .homeFallback))
    }

    @Test func returnsNilWhenNothingFoundAndNoHome() throws {
        let walker = DirectoryWalker(fileSystem: filesystem, home: nil)
        #expect(try walker.findManifest(startingAt: "/tmp/work") == nil)
    }

    @Test func stopsSilentlyOnPermissionDenied() throws {
        filesystem.deniedPaths = ["/locked/spells.yaml", "/locked/.spells.yaml"]
        filesystem.files = ["/home/user/spells.yaml"]
        let location = try walker.findManifest(startingAt: "/locked")
        #expect(location?.source == .homeFallback)
    }

    @Test func sixtyIterationLimit_isHardError() {
        let deepPath = "/" + Array(repeating: "x", count: 80).joined(separator: "/")
        let error = #expect(throws: SpellbookError.self) {
            try walker.findManifest(startingAt: deepPath)
        }
        guard case .walkUpTooDeep = error else {
            Issue.record("expected walkUpTooDeep, got \(error)")
            return
        }
    }
}
