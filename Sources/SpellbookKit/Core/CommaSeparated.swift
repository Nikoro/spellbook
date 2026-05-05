enum CommaSeparated {
    static func split(_ raw: String) -> [String] {
        raw.split(separator: ",").map(trim)
    }

    private static func trim(_ slice: Substring) -> String {
        var start = slice.startIndex
        var end = slice.endIndex
        while start < end, slice[start] == " " { start = slice.index(after: start) }
        while end > start, slice[slice.index(before: end)] == " " {
            end = slice.index(before: end)
        }
        return String(slice[start..<end])
    }
}
