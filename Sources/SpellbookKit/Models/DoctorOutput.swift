public struct DoctorOutput: Equatable, Sendable {
    public let report: DoctorReport
    public let fixNotes: [String]

    public init(report: DoctorReport, fixNotes: [String] = []) {
        self.report = report
        self.fixNotes = fixNotes
    }

    public var exitCode: Int32 {
        report.hasErrors ? 1 : 0
    }

    public var lines: [String] {
        var output: [String] = report.items.map { item in
            let prefix: String
            switch item.severity {
            case .error: prefix = "[ERROR]"
            case .warning: prefix = "[WARN]"
            case .info: prefix = "[INFO]"
            }
            return "\(prefix) \(item.message)"
        }
        if !fixNotes.isEmpty {
            output.append("")
            output.append(contentsOf: fixNotes.map { "[FIX] \($0)" })
        }
        return output
    }
}
