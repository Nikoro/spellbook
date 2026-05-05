enum DuplicateTokens {
    static func find(_ tokens: [String]) -> [String] {
        var seen: Set<String> = []
        var duplicates: [String] = []
        for token in tokens {
            if seen.contains(token) {
                if !duplicates.contains(token) { duplicates.append(token) }
            } else {
                seen.insert(token)
            }
        }
        return duplicates
    }
}
