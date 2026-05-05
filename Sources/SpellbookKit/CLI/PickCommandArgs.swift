import Foundation

public enum PickCommandArgs {
    public static func parseStdin(_ raw: String) -> [String] {
        let lines = raw.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)
        return lines.filter { !$0.isEmpty }
    }
}
