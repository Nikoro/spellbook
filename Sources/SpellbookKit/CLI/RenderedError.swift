public struct RenderedError {
    public let header: String
    public let context: String?
    public let body: String?
    public let suggestion: String?

    public init(
        header: String,
        context: String? = nil,
        body: String? = nil,
        suggestion: String? = nil
    ) {
        self.header = header
        self.context = context
        self.body = body
        self.suggestion = suggestion
    }

    public func formatted(color: Bool) -> String {
        ErrorTemplates.compose(
            header: ErrorTemplates.header(header, color: color),
            context: context.map { ErrorTemplates.context($0, color: color) },
            body: body.map { ErrorTemplates.body($0) },
            suggestion: suggestion.map { ErrorTemplates.suggestion($0, color: color) }
        )
    }
}
