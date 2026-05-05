public struct DoctorReport: Equatable, Sendable {
    public let items: [DiagnosticItem]

    public init(items: [DiagnosticItem]) {
        self.items = items
    }

    public var hasErrors: Bool {
        items.contains { $0.severity == .error }
    }

    public var hasWarnings: Bool {
        items.contains { $0.severity == .warning }
    }
}
