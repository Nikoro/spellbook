import Foundation

extension YAMLParser {
    func parseSequence(
        indent: Int,
        lines: [YAMLLine],
        index: inout Int
    ) throws -> YAMLNode {
        var items: [YAMLNode] = []
        while index < lines.count {
            let line = lines[index]
            guard case .mapping(let content, _) = line.kind, line.indent == indent else { break }
            guard content.hasPrefix("-") else { break }
            let tail = try sequenceItemTail(content, line: line.number)
            items.append(.scalar(unquote(tail)))
            index += 1
        }
        return .sequence(items)
    }

    private func sequenceItemTail(_ content: String, line: Int) throws -> String {
        let afterDash: String
        if content == "-" {
            afterDash = ""
        } else if content.hasPrefix("- ") {
            afterDash = String(content.dropFirst(2))
        } else {
            throw SpellbookError.unsupportedSequenceItem(line: line)
        }
        let trimmed = afterDash.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("- ") || trimmed.hasPrefix("[") {
            throw SpellbookError.unsupportedSequenceItem(line: line)
        }
        if containsUnquotedColon(trimmed) {
            throw SpellbookError.unsupportedSequenceItem(line: line)
        }
        return trimmed
    }

    func parseFlowSequence(_ text: String, line: Int) throws -> YAMLNode {
        guard text.hasSuffix("]") else {
            throw SpellbookError.unclosedFlowSequence(line: line)
        }
        let inner = String(text.dropFirst().dropLast())
        if inner.trimmingCharacters(in: .whitespaces).isEmpty { return .sequence([]) }
        let parts = try splitFlowItems(inner, line: line)
        return .sequence(parts.map { .scalar(unquote($0.trimmingCharacters(in: .whitespaces))) })
    }

    private func splitFlowItems(_ text: String, line: Int) throws -> [String] {
        var items: [String] = []
        var scanner = YAMLQuoteScanner()
        var current = ""
        for char in text {
            if !scanner.consume(char), char == "," {
                items.append(current)
                current = ""
                continue
            }
            current.append(char)
        }
        if scanner.isOpen {
            throw SpellbookError.unmatchedQuote(line: line, column: text.count + 1)
        }
        items.append(current)
        return items
    }

    private func containsUnquotedColon(_ text: String) -> Bool {
        var scanner = YAMLQuoteScanner()
        for char in text {
            if scanner.consume(char) { continue }
            if char == ":" { return true }
        }
        return false
    }
}
