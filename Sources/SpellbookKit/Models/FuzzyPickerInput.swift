public enum FuzzyPickerInput: Equatable, Sendable {
    case char(Character)
    case backspace
    case digit(Int)
    case moveUp
    case moveDown
    case confirm
    case cancel
}
