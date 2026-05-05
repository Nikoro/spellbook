public enum DoctorFixer {
    public struct Assessment: Equatable {
        public let shouldReactivate: Bool
        public let reasons: [String]

        public init(shouldReactivate: Bool, reasons: [String]) {
            self.shouldReactivate = shouldReactivate
            self.reasons = reasons
        }
    }

    public static func assess(report: DoctorReport) -> Assessment {
        let reasons = report.items.compactMap { item -> String? in
            guard item.category == .wrappers else { return nil }
            let message = item.message
            if message.hasPrefix("New spells not yet activated")
                || message.hasPrefix("Stale wrappers for removed spells")
                || message.hasPrefix("Project not yet activated")
                || message.hasPrefix("No state file found") {
                return message
            }
            return nil
        }
        return Assessment(shouldReactivate: !reasons.isEmpty, reasons: reasons)
    }
}
