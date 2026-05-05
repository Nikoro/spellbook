import Foundation

struct YAMLParser {
    func parse(_ lines: [YAMLLine]) throws -> YAMLNode {
        var index = 0
        guard let first = firstMapping(in: lines, from: index) else { return .null }
        return try parseMap(lines: lines, index: &index, indent: first.indent)
    }

    private func parseMap(
        lines: [YAMLLine],
        index: inout Int,
        indent: Int
    ) throws -> YAMLNode {
        var entries: [MapEntry] = []
        while index < lines.count {
            let line = lines[index]
            guard case .mapping(let content, let description) = line.kind else { break }
            if line.indent < indent { break }
            if line.indent > indent { throw SpellbookError.unexpectedIndent(line: line.number) }
            index += 1
            let (key, rest) = try splitKeyValue(content, line: line.number)
            let value = try parseValue(rest: rest, parentIndent: indent, lines: lines, index: &index)
            entries.append(MapEntry(key: key, description: description, value: value))
        }
        return .map(entries)
    }

    private func parseValue(
        rest: String,
        parentIndent: Int,
        lines: [YAMLLine],
        index: inout Int
    ) throws -> YAMLNode {
        let trimmed = rest.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return try parseDeeperValue(parentIndent: parentIndent, lines: lines, index: &index)
        }
        if trimmed == "|" {
            return .scalar(collectBlockScalar(lines: lines, index: &index))
        }
        if trimmed.hasPrefix("[") {
            return try parseFlowSequence(trimmed, line: lines[safeIndexBefore: index]?.number ?? 0)
        }
        return .scalar(unquote(trimmed))
    }

    private func parseDeeperValue(
        parentIndent: Int,
        lines: [YAMLLine],
        index: inout Int
    ) throws -> YAMLNode {
        guard let next = firstMapping(in: lines, from: index) else { return .null }
        if next.indent <= parentIndent { return .null }
        if case .mapping(let content, _) = next.kind, content.hasPrefix("- ") || content == "-" {
            return try parseSequence(indent: next.indent, lines: lines, index: &index)
        }
        return try parseMap(lines: lines, index: &index, indent: next.indent)
    }

    private func firstMapping(in lines: [YAMLLine], from start: Int) -> YAMLLine? {
        var cursor = start
        while cursor < lines.count {
            if case .mapping = lines[cursor].kind { return lines[cursor] }
            cursor += 1
        }
        return nil
    }
}

extension Array where Element == YAMLLine {
    fileprivate subscript(safeIndexBefore index: Int) -> YAMLLine? {
        let target = index - 1
        guard target >= 0, target < count else { return nil }
        return self[target]
    }
}
