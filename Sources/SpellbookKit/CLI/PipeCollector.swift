import Foundation

final class PipeCollector: @unchecked Sendable {
    private let stdoutHandle: FileHandle
    private let stderrHandle: FileHandle
    private let bufferCap: Int
    private let overflowHandler: @Sendable ([UInt8], [UInt8]) -> Void
    private let lock = NSLock()
    private let group = DispatchGroup()

    private var stdoutBuffer = Data()
    private var stderrBuffer = Data()
    private(set) var didOverflow = false

    var stdoutBytes: [UInt8] { Array(stdoutBuffer) }
    var stderrBytes: [UInt8] { Array(stderrBuffer) }

    init(
        stdoutHandle: FileHandle,
        stderrHandle: FileHandle,
        bufferCap: Int,
        overflowHandler: @escaping @Sendable ([UInt8], [UInt8]) -> Void
    ) {
        self.stdoutHandle = stdoutHandle
        self.stderrHandle = stderrHandle
        self.bufferCap = bufferCap
        self.overflowHandler = overflowHandler
    }

    func start() {
        startReader(handle: stdoutHandle, isStderr: false)
        startReader(handle: stderrHandle, isStderr: true)
    }

    func wait() {
        group.wait()
    }
}

// MARK: - Pipe reading

extension PipeCollector {
    private func startReader(
        handle: FileHandle,
        isStderr: Bool
    ) {
        group.enter()
        DispatchQueue.global().async { [self] in
            defer { group.leave() }
            readLoop(handle: handle, isStderr: isStderr)
        }
    }

    private func readLoop(
        handle: FileHandle,
        isStderr: Bool
    ) {
        while true {
            let chunk = handle.availableData
            if chunk.isEmpty { break }

            lock.lock()
            if didOverflow {
                lock.unlock()
                forwardLive(chunk, isStderr: isStderr)
                continue
            }
            appendToBuffer(chunk, isStderr: isStderr)
            if bufferExceeded {
                triggerOverflow()
                lock.unlock()
                continue
            }
            lock.unlock()
        }
    }
}

// MARK: - Buffer management

extension PipeCollector {
    private var bufferExceeded: Bool {
        stdoutBuffer.count > bufferCap
            || stderrBuffer.count > bufferCap
    }

    private func appendToBuffer(
        _ chunk: Data,
        isStderr: Bool
    ) {
        if isStderr {
            stderrBuffer.append(chunk)
        } else {
            stdoutBuffer.append(chunk)
        }
    }

    private func triggerOverflow() {
        didOverflow = true
        let flushOut = Array(stdoutBuffer)
        let flushErr = Array(stderrBuffer)
        stdoutBuffer = Data()
        stderrBuffer = Data()
        overflowHandler(flushOut, flushErr)
    }

    private func forwardLive(
        _ chunk: Data,
        isStderr: Bool
    ) {
        if isStderr {
            FileHandle.standardError.write(chunk)
        } else {
            FileHandle.standardOutput.write(chunk)
        }
    }
}
