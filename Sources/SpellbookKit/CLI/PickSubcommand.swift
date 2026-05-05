import Foundation

enum PickSubcommand {
    static func run() {
        let raw = readAllStdin()
        let candidates = PickCommandArgs.parseStdin(raw)
        guard !candidates.isEmpty else { return }
        var source = DevTTYSource()
        if let selection = PickCommand().run(
            candidates: candidates, source: &source
        ) {
            print(selection)
        }
    }

    private static func readAllStdin() -> String {
        let data = FileHandle.standardInput.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
}
