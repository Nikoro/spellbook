public struct ParamDefinition: Equatable, Sendable {
    public let name: String
    public let description: String?
    public let shape: ParamShape
    public let schema: ParamSchema

    public init(
        name: String,
        description: String? = nil,
        shape: ParamShape = .init(),
        schema: ParamSchema = .init()
    ) {
        self.name = name
        self.description = description
        self.shape = shape
        self.schema = schema
    }

    public var flags: [String] { shape.flags }
    public var isRequired: Bool { shape.isRequired }
    public var isPositional: Bool { shape.isPositional }
    public var type: ParamType { schema.type }
    public var values: [String] { schema.values }
    public var defaultValue: String? { schema.defaultValue }
}

extension ParamDefinition {
    public init(
        name: String,
        description: String? = nil,
        isRequired: Bool,
        isPositional: Bool
    ) {
        self.init(
            name: name,
            description: description,
            shape: ParamShape(isRequired: isRequired, isPositional: isPositional)
        )
    }
}
