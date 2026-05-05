import Darwin
import Foundation

public final class DevTTYSource: TTYSource {
    private var readHandle: FileHandle?
    private var writeHandle: FileHandle?
    private var savedTermios: termios?
    private var readFd: Int32 = -1

    public init() {}

    public var isTTY: Bool {
        let descriptor = open("/dev/tty", O_RDWR)
        defer { if descriptor >= 0 { close(descriptor) } }
        return descriptor >= 0 && isatty(descriptor) != 0
    }

    public func enterRawMode() throws {
        let descriptor = open("/dev/tty", O_RDWR)
        guard descriptor >= 0 else {
            throw SpellbookError.ttyUnavailable
        }
        readFd = descriptor
        readHandle = FileHandle(fileDescriptor: descriptor, closeOnDealloc: false)
        writeHandle = FileHandle(fileDescriptor: descriptor, closeOnDealloc: false)
        var current = termios()
        guard tcgetattr(descriptor, &current) == 0 else {
            throw SpellbookError.ttyUnavailable
        }
        savedTermios = current
        cfmakeraw(&current)
        tcsetattr(descriptor, TCSANOW, &current)
    }

    public func restoreMode() {
        if var saved = savedTermios, readFd >= 0 {
            tcsetattr(readFd, TCSANOW, &saved)
        }
        if readFd >= 0 { close(readFd); readFd = -1 }
        readHandle = nil
        writeHandle = nil
        savedTermios = nil
    }

    public func readByte() throws -> UInt8? {
        guard readFd >= 0 else { return nil }
        var byte: UInt8 = 0
        let count = read(readFd, &byte, 1)
        return count == 1 ? byte : nil
    }

    public func write(_ string: String) {
        guard let writeHandle = writeHandle else { return }
        if let data = string.data(using: .utf8) {
            writeHandle.write(data)
        }
    }
}
