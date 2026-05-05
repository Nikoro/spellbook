public enum InteractivePicker {

    public enum Result: Equatable {
        case selected(Int)
        case cancelled
    }

    enum Input {
        case moveUp
        case moveDown
        case confirm
        case cancel
        case digit(Int)
        case unknown
    }

    enum Action {
        case moveTo(Int)
        case select(Int)
        case confirm
        case cancel
        case ignore
    }

    public static func pick(
        options: [String],
        prompt: String,
        terminal: TerminalProtocol
    ) throws -> Result {
        guard !options.isEmpty else { return .cancelled }
        return try terminal.withRawMode {
            try runLoop(
                options: options,
                prompt: prompt,
                terminal: terminal
            )
        }
    }

    static func runLoop(
        options: [String],
        prompt: String,
        terminal: TerminalProtocol
    ) throws -> Result {
        terminal.hideCursor()
        var selected = 0
        renderOptions(options, selected: selected, terminal: terminal)
        while true {
            guard let input = readInput(from: terminal) else {
                terminal.showCursor()
                return .cancelled
            }
            let action = applyInput(
                input, selected: selected, count: options.count
            )
            switch action {
            case .moveTo(let idx):
                selected = idx
                terminal.moveCursorUp(options.count)
                renderOptions(options, selected: selected, terminal: terminal)
            case .select(let idx):
                terminal.showCursor()
                return .selected(idx)
            case .confirm:
                terminal.showCursor()
                return .selected(selected)
            case .cancel:
                terminal.showCursor()
                return .cancelled
            case .ignore:
                continue
            }
        }
    }

    static func readInput(from terminal: TerminalProtocol) -> Input? {
        guard let byte = try? terminal.readByte() else { return nil }
        switch byte {
        case 0x1B: return readEscape(from: terminal)
        case 0x0D, 0x0A: return .confirm
        case 0x71: return .cancel   // q
        case 0x6A: return .moveDown // j
        case 0x6B: return .moveUp   // k
        case 0x31...0x39: return .digit(Int(byte) - 0x30)
        default: return .unknown
        }
    }

    static func readEscape(from terminal: TerminalProtocol) -> Input {
        guard let next = try? terminal.readByte(), next == 0x5B else {
            return .cancel
        }
        guard let arrow = try? terminal.readByte() else {
            return .cancel
        }
        switch arrow {
        case 0x41: return .moveUp   // ESC [ A
        case 0x42: return .moveDown // ESC [ B
        default: return .unknown
        }
    }

    static func applyInput(
        _ input: Input, selected: Int, count: Int
    ) -> Action {
        switch input {
        case .moveUp:
            return .moveTo(selected > 0 ? selected - 1 : count - 1)
        case .moveDown:
            return .moveTo(selected < count - 1 ? selected + 1 : 0)
        case .confirm:
            return .confirm
        case .cancel:
            return .cancel
        case .digit(let number):
            return number <= count ? .select(number - 1) : .ignore
        case .unknown:
            return .ignore
        }
    }

    static func renderOptions(
        _ options: [String],
        selected: Int,
        terminal: TerminalProtocol
    ) {
        for (index, option) in options.enumerated() {
            terminal.clearLine()
            let marker = index == selected ? ">" : " "
            terminal.writeLine("\(marker) \(option)")
        }
    }
}
