public indirect enum DefaultBranch: Equatable, Sendable {
    case none
    case key(String)
    case inline(SpellDefinition)
}
