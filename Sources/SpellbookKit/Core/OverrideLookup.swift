public protocol OverrideLookup {
    func externalCommand(for spellName: String) -> String?
}
