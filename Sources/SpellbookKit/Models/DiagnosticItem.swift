public struct DiagnosticItem: Equatable, Sendable {
    public let severity: DiagnosticSeverity
    public let category: DiagnosticCategory
    public let message: String

    public init(severity: DiagnosticSeverity, category: DiagnosticCategory, message: String) {
        self.severity = severity
        self.category = category
        self.message = message
    }
}
