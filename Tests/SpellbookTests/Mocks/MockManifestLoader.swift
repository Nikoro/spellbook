@testable import SpellbookKit

public final class MockManifestLoader: ManifestLoader {
    public struct LoadCall: Equatable {
        public let extends: String
        public let basePath: String
    }

    public var responses: [String: LoadedManifest] = [:]
    public var errors: [String: SpellbookError] = [:]
    public private(set) var loadCalls: [LoadCall] = []

    public init() {}

    public func load(extends: String, from basePath: String) throws -> LoadedManifest {
        loadCalls.append(LoadCall(extends: extends, basePath: basePath))
        if let error = errors[extends] { throw error }
        if let response = responses[extends] { return response }
        throw SpellbookError.missingExtendsParent(path: extends)
    }
}
