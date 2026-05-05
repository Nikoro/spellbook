import Foundation

extension YAMLParser {
    func splitKeyValue(_ content: String, line: Int) throws -> (String, String) {
        var scanner = YAMLQuoteScanner()
        var colonAt: Int?
        for (index, char) in content.enumerated() {
            if scanner.consume(char) { continue }
            if char == ":" { colonAt = index; break }
        }
        guard let position = colonAt else {
            throw SpellbookError.missingColon(line: line)
        }
        let chars = Array(content)
        let key = String(chars[0..<position]).trimmingCharacters(in: .whitespaces)
        let rest = position + 1 < chars.count ? String(chars[(position + 1)...]) : ""
        return (key, rest)
    }

    func collectBlockScalar(lines: [YAMLLine], index: inout Int) -> String {
        var bodies: [String] = []
        while index < lines.count {
            guard case .blockScalarBody(let raw) = lines[index].kind else { break }
            bodies.append(raw)
            index += 1
        }
        let strip = minLeadingSpaces(of: bodies)
        var result = bodies.map { dedent($0, by: strip) }
        while result.last?.isEmpty == true { result.removeLast() }
        return result.joined(separator: "\n")
    }

    func unquote(_ text: String) -> String {
        guard text.count >= 2 else { return text }
        let first = text.first
        let last = text.last
        if first == "\"" && last == "\"" {
            return unescape(String(text.dropFirst().dropLast()))
        }
        if first == "'" && last == "'" {
            return String(text.dropFirst().dropLast())
        }
        return text
    }

    private func unescape(_ text: String) -> String {
        var out = ""
        var escape = false
        for char in text {
            if escape {
                out.append(escapedReplacement(char))
                escape = false
                continue
            }
            if char == "\\" { escape = true; continue }
            out.append(char)
        }
        return out
    }

    private func escapedReplacement(_ char: Character) -> Character {
        switch char {
        case "n": return "\n"
        case "t": return "\t"
        case "\"": return "\""
        case "\\": return "\\"
        default: return char
        }
    }

    private func minLeadingSpaces(of bodies: [String]) -> Int {
        var minimum: Int?
        for body in bodies where !body.trimmingCharacters(in: .whitespaces).isEmpty {
            let lead = countLeadingSpaces(body)
            if let current = minimum {
                if lead < current { minimum = lead }
            } else {
                minimum = lead
            }
        }
        return minimum ?? 0
    }

    private func countLeadingSpaces(_ text: String) -> Int {
        var count = 0
        for char in text {
            if char == " " { count += 1 } else { break }
        }
        return count
    }

    private func dedent(_ text: String, by count: Int) -> String {
        if text.count <= count { return "" }
        return String(text.dropFirst(count))
    }
}
