import Testing
@testable import SpellbookKit

struct WorkingDirectoryResolverTests {

    private let resolver = WorkingDirectoryResolver()

    // MARK: - Default (nil) returns invocation cwd

    @Test func nilWorkingDir_returnsInvocationCwd() {
        let result = resolver.resolve(
            workingDir: nil,
            originManifestDir: "/manifest",
            invocationCwd: "/user/project",
            home: "/Users/me"
        )
        #expect(result == "/user/project")
    }

    // MARK: - Absolute path returned as-is

    @Test func absolutePath_returnedAsIs() {
        let result = resolver.resolve(
            workingDir: "/tmp/build",
            originManifestDir: "/manifest",
            invocationCwd: "/user/project",
            home: "/Users/me"
        )
        #expect(result == "/tmp/build")
    }

    // MARK: - Tilde expansion

    @Test func tildeAlone_expandsToHome() {
        let result = resolver.resolve(
            workingDir: "~",
            originManifestDir: "/manifest",
            invocationCwd: "/user/project",
            home: "/Users/me"
        )
        #expect(result == "/Users/me")
    }

    @Test func tildeSlashPath_expandsToHomeSubdir() {
        let result = resolver.resolve(
            workingDir: "~/projects/app",
            originManifestDir: "/manifest",
            invocationCwd: "/user/project",
            home: "/Users/me"
        )
        #expect(result == "/Users/me/projects/app")
    }

    @Test func tildeWithNoHome_returnsRawValue() {
        let result = resolver.resolve(
            workingDir: "~/stuff",
            originManifestDir: "/manifest",
            invocationCwd: "/user/project",
            home: nil
        )
        #expect(result == "~/stuff")
    }

    // MARK: - Relative path resolves from origin manifest directory

    @Test func relativePath_resolvesFromOriginDir() {
        let result = resolver.resolve(
            workingDir: "src",
            originManifestDir: "/shared/base",
            invocationCwd: "/user/project",
            home: "/Users/me"
        )
        #expect(result == "/shared/base/src")
    }

    @Test func dotSlashRelative_resolvesFromOriginDir() {
        let result = resolver.resolve(
            workingDir: "./build",
            originManifestDir: "/shared/base",
            invocationCwd: "/user/project",
            home: nil
        )
        #expect(result == "/shared/base/./build")
    }

    @Test func dotDotRelative_resolvesFromOriginDir() {
        let result = resolver.resolve(
            workingDir: "../sibling",
            originManifestDir: "/shared/base",
            invocationCwd: "/user/project",
            home: nil
        )
        #expect(result == "/shared/base/../sibling")
    }
}
