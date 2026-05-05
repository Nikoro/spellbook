public struct SpellDefinition: Equatable, Sendable {
    public let identity: SpellIdentity
    public let body: SpellBody
    public let runtime: SpellRuntime

    public init(
        identity: SpellIdentity,
        body: SpellBody = .empty,
        runtime: SpellRuntime = .default
    ) {
        self.identity = identity
        self.body = body
        self.runtime = runtime
    }

    public var name: String { identity.name }
    public var description: String? { identity.description }
    public var aliases: [String] { identity.aliases }
    public var script: String? { body.script }
    public var params: [ParamDefinition] { body.params }
    public var switchBranches: SwitchDefinition? { body.switchBranches }
    public var override: Bool { runtime.override }
    public var silent: Bool { runtime.silent }
    public var workingDir: String? { runtime.workingDir }
    public var shell: String? { runtime.shell }
}

extension SpellDefinition {
    public init(
        name: String,
        description: String? = nil,
        script: String? = nil
    ) {
        self.init(
            identity: SpellIdentity(name: name, description: description),
            body: SpellBody(script: script)
        )
    }
}
