import Foundation
import Testing

public enum Snapshot {
    public static func assert(
        _ actual: String,
        named name: String,
        fileID: String = #fileID,
        filePath: String = #filePath,
        line: Int = #line,
        column: Int = #column
    ) {
        let url = fileURL(for: name)
        if shouldRecord() || !FileManager.default.fileExists(atPath: url.path) {
            write(actual, to: url)
            return
        }
        let expected = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
        let location = SourceLocation(fileID: fileID, filePath: filePath, line: line, column: column)
        #expect(
            actual == expected,
            "Snapshot mismatch: \(name). Re-record with RECORD_SNAPSHOTS=1 swift test.",
            sourceLocation: location
        )
    }

    private static func shouldRecord() -> Bool {
        ProcessInfo.processInfo.environment["RECORD_SNAPSHOTS"] == "1"
    }

    private static func write(_ content: String, to url: URL) {
        let directory = url.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? content.write(to: url, atomically: true, encoding: .utf8)
    }

    private static func fileURL(for name: String) -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("__Snapshots__")
            .appendingPathComponent("\(name).txt")
    }
}
