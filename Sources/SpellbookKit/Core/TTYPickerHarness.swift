public enum TTYPickerHarness {
    public static func run<Source: TTYSource>(
        candidates: [String],
        source: inout Source
    ) -> FuzzyPickerOutcome {
        guard source.isTTY else { return .cancelled }
        do {
            try source.enterRawMode()
        } catch {
            return .cancelled
        }
        defer { source.restoreMode() }
        var state = FuzzyPickerState(candidates: candidates)
        var previousLineCount = 0
        previousLineCount = renderState(state, source: source, previousLineCount: 0)
        while true {
            guard let input = readInput(from: &source) else {
                clearBlock(source: source, lineCount: previousLineCount)
                return .cancelled
            }
            let outcome = state.apply(input)
            switch outcome {
            case .pending:
                previousLineCount = renderState(
                    state, source: source, previousLineCount: previousLineCount
                )
            case .accepted, .cancelled:
                clearBlock(source: source, lineCount: previousLineCount)
                return outcome
            }
        }
    }

    static func readInput<Source: TTYSource>(
        from source: inout Source
    ) -> FuzzyPickerInput? {
        guard let first = readOptional(from: &source) else { return nil }
        return TTYInputDecoder.decode(byte: first) { readOptional(from: &source) }
    }

    private static func readOptional<Source: TTYSource>(
        from source: inout Source
    ) -> UInt8? {
        (try? source.readByte()).flatMap { $0 }
    }

    @discardableResult
    private static func renderState<Source: TTYSource>(
        _ state: FuzzyPickerState,
        source: Source,
        previousLineCount: Int
    ) -> Int {
        clearBlock(source: source, lineCount: previousLineCount)
        var lines: [String] = ["> " + state.query]
        for (index, entry) in state.visible.enumerated() {
            let marker = index == state.selectedIndex ? ">" : " "
            lines.append(marker + " " + entry.candidate)
        }
        // Join with CRLF so each row starts at column 0, but do NOT emit a
        // trailing CRLF — that would advance the cursor past the last line
        // and make subsequent "cursor up N" over-correct by one line.
        source.write(lines.joined(separator: "\r\n"))
        return lines.count
    }

    private static func clearBlock<Source: TTYSource>(
        source: Source, lineCount: Int
    ) {
        guard lineCount > 0 else { return }
        // Cursor sits at the end of the last rendered line. Move it to the
        // start of the block (lineCount - 1 rows up), then erase to end of
        // screen.
        let rowsUp = lineCount - 1
        if rowsUp > 0 {
            source.write("\r\u{1B}[\(rowsUp)A\u{1B}[J")
        } else {
            source.write("\r\u{1B}[J")
        }
    }
}
