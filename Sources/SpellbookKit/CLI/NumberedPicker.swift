public enum NumberedPicker {

    public static func pick(
        options: [String],
        prompt: String,
        terminal: TerminalProtocol
    ) -> InteractivePicker.Result {
        guard !options.isEmpty else { return .cancelled }
        terminal.writeLine(prompt)
        for (index, option) in options.enumerated() {
            terminal.writeLine("  \(index + 1)) \(option)")
        }
        terminal.writeLine("Enter number (1-\(options.count)):")
        guard let line = readLine(from: terminal),
              let number = Int(line),
              number >= 1, number <= options.count else {
            return .cancelled
        }
        return .selected(number - 1)
    }

    static func readLine(
        from terminal: TerminalProtocol
    ) -> String? {
        var bytes: [UInt8] = []
        while let byte = try? terminal.readByte() {
            if byte == 0x0A || byte == 0x0D { break }
            bytes.append(byte)
        }
        guard !bytes.isEmpty else { return nil }
        return String(bytes: bytes, encoding: .utf8)
    }
}
