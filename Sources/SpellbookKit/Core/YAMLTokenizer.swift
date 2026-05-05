import Foundation

struct YAMLTokenizer {
    func tokenize(_ source: String) throws -> [YAMLLine] {
        var tokens: [YAMLLine] = []
        var blockMinIndent: Int?
        var number = 0
        for raw in source.components(separatedBy: "\n") {
            number += 1
            if let minIndent = blockMinIndent, continuesBlockScalar(raw, minIndent: minIndent) {
                let indent = leadingSpaces(raw)
                tokens.append(YAMLLine(number: number, indent: indent, kind: .blockScalarBody(raw: raw)))
                continue
            }
            blockMinIndent = nil
            guard let token = try parseLine(raw, number: number) else { continue }
            tokens.append(token)
            blockMinIndent = openingBlockScalarIndent(from: token)
        }
        return tokens
    }

    private func parseLine(_ raw: String, number: Int) throws -> YAMLLine? {
        if hasTabInIndent(raw) { throw SpellbookError.tabIndentation(line: number) }
        let indent = leadingSpaces(raw)
        let rest = String(raw.dropFirst(indent))
        if rest.isEmpty || rest.hasPrefix("#") { return nil }
        let (content, description) = try stripComment(rest, number: number)
        if content.isEmpty { return nil }
        return YAMLLine(number: number, indent: indent, kind: .mapping(content: content, description: description))
    }

    private func continuesBlockScalar(_ line: String, minIndent: Int) -> Bool {
        if line.trimmingCharacters(in: .whitespaces).isEmpty { return true }
        return leadingSpaces(line) > minIndent
    }

    private func openingBlockScalarIndent(from token: YAMLLine) -> Int? {
        guard case .mapping(let content, _) = token.kind, content.hasSuffix("|") else { return nil }
        return token.indent
    }

    private func leadingSpaces(_ line: String) -> Int {
        var count = 0
        for char in line {
            if char == " " { count += 1 } else { break }
        }
        return count
    }

    private func hasTabInIndent(_ line: String) -> Bool {
        for char in line {
            if char == " " { continue }
            return char == "\t"
        }
        return false
    }
}

extension YAMLTokenizer {
    fileprivate func stripComment(_ text: String, number: Int) throws -> (String, String?) {
        let chars = Array(text)
        var scanner = YAMLQuoteScanner()
        var commentAt: Int?
        for (index, char) in chars.enumerated() {
            if scanner.consume(char) { continue }
            if char == "#" { commentAt = index; break }
        }
        if scanner.isOpen {
            throw SpellbookError.unmatchedQuote(line: number, column: chars.count + 1)
        }
        return splitAtComment(chars, commentStart: commentAt ?? chars.count)
    }

    fileprivate func splitAtComment(_ chars: [Character], commentStart: Int) -> (String, String?) {
        if commentStart >= chars.count {
            return (YAMLTrimmer.rtrim(String(chars)), nil)
        }
        let before = YAMLTrimmer.rtrim(String(chars[0..<commentStart]))
        let isDescription = commentStart + 1 < chars.count && chars[commentStart + 1] == "#"
        guard isDescription else { return (before, nil) }
        let descChars = chars[(commentStart + 2)...]
        let description = String(descChars).trimmingCharacters(in: .whitespaces)
        return (before, description.isEmpty ? nil : description)
    }
}
