struct CompletionRequest {
    let tokens: [String]
    let cword: Int
    let wrapper: String

    var cursorWord: String {
        guard cword >= 0, cword < tokens.count else { return "" }
        return tokens[cword]
    }

    func isCursor(_ absoluteIndex: Int) -> Bool { absoluteIndex == cword }
}
