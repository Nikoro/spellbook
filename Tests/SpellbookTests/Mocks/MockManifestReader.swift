@testable import SpellbookKit

public final class MockManifestReader: ManifestReader {
    public var manifests: [String: SpellbookManifest] = [:]

    public init() {}

    public func read(at path: String) throws -> SpellbookManifest {
        guard let manifest = manifests[path] else {
            throw SpellbookError.missingExtendsParent(path: path)
        }
        return manifest
    }
}
