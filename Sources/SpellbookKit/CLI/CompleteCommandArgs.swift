public struct CompleteCommandArgs: Equatable {
    public let wrapper: String
    public let cword: Int
    public let tokens: [String]

    public static func parse(_ arguments: [String]) throws -> CompleteCommandArgs {
        guard let wrapper = arguments.first, !wrapper.isEmpty else {
            throw SpellbookError.completeMissingWrapper
        }
        let rest = Array(arguments.dropFirst())
        let cword = try extractCword(rest)
        let tokens = try extractTokens(rest)
        return CompleteCommandArgs(wrapper: wrapper, cword: cword, tokens: tokens)
    }

    private static func extractCword(_ args: [String]) throws -> Int {
        guard let flagIndex = args.firstIndex(of: "--cword"),
              flagIndex + 1 < args.count else {
            throw SpellbookError.completeMissingCword
        }
        guard let value = Int(args[flagIndex + 1]), value >= 0 else {
            throw SpellbookError.completeInvalidCword(value: args[flagIndex + 1])
        }
        return value
    }

    private static func extractTokens(_ args: [String]) throws -> [String] {
        guard let sepIndex = args.firstIndex(of: "--") else {
            throw SpellbookError.completeMissingSeparator
        }
        return Array(args[(sepIndex + 1)...])
    }
}
