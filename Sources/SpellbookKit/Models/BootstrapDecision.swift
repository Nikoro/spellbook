public enum BootstrapDecision: Equatable, Sendable {
    case alreadyConfigured
    case offerInteractive(shell: String, rcPath: String, integrationLine: String)
    case printManual(shell: String, integrationLine: String)
    case unknownShell
}
