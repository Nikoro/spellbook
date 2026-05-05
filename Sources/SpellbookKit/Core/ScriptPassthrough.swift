enum ScriptPassthrough {
    private static let token: [Character] = Array("...args")

    static func count(in script: String) -> Int {
        var hits = 0
        var cursor = script.startIndex
        while let next = advance(script, from: cursor) {
            hits += 1
            cursor = next
        }
        return hits
    }

    private static func advance(_ script: String, from start: String.Index) -> String.Index? {
        var index = start
        while index < script.endIndex {
            if matches(script, at: index) {
                return script.index(index, offsetBy: token.count)
            }
            index = script.index(after: index)
        }
        return nil
    }

    private static func matches(_ script: String, at start: String.Index) -> Bool {
        var cursor = start
        for char in token {
            if cursor >= script.endIndex || script[cursor] != char { return false }
            cursor = script.index(after: cursor)
        }
        return true
    }
}
