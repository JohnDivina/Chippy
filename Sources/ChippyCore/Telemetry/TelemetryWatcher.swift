import Foundation

/// Real-time actor monitoring active session transcripts on disk with kernel-level zero-latency
/// DispatchSource event notifications and streaming parsed `AgentEvent` items over an AsyncStream.
public actor TelemetryWatcher {
    private var fileOffset: UInt64 = 0
    private var isWatching: Bool = false
    private var watchTask: Task<Void, Never>?
    private var continuation: AsyncStream<AgentEvent>.Continuation?
    private var fileDescriptor: Int32 = -1
    private var dispatchSource: DispatchSourceFileSystemObject?

    private let adapter: any TranscriptAdapter
    private let redactor: Redactor

    public init(adapter: any TranscriptAdapter = AntigravityAdapter(), redactor: Redactor = Redactor()) {
        self.adapter = adapter
        self.redactor = redactor
    }

    /// Starts tailing the specified transcript file in real time.
    /// If `readFromBeginning` is false, monitoring starts at the current file tail (zero backlog).
    public func startWatching(fileURL: URL, readFromBeginning: Bool = true, maxInitialLines: Int? = 30) -> AsyncStream<AgentEvent> {
        stopWatching()

        let currentSize = (try? FileManager.default.attributesOfItem(atPath: fileURL.path)[.size] as? UInt64) ?? 0

        if !readFromBeginning {
            self.fileOffset = currentSize
        } else {
            self.fileOffset = 0
        }

        self.isWatching = true

        let stream = AsyncStream<AgentEvent> { cont in
            self.continuation = cont
        }

        // 1. Initial read if requested
        if readFromBeginning && currentSize > 0 {
            readInitialTailBytes(from: fileURL, currentSize: currentSize, maxLines: maxInitialLines)
        }

        // 2. Kernel-level DispatchSource for instant (<1ms) file notification
        let fd = open(fileURL.path, O_RDONLY)
        if fd >= 0 {
            self.fileDescriptor = fd
            let source = DispatchSource.makeFileSystemObjectSource(
                fileDescriptor: fd,
                eventMask: [.write, .extend, .attrib],
                queue: DispatchQueue.global(qos: .userInteractive)
            )
            source.setEventHandler { [weak self] in
                Task { [weak self] in
                    await self?.pollAppendedBytes(from: fileURL)
                }
            }
            source.setCancelHandler {
                close(fd)
            }
            source.resume()
            self.dispatchSource = source
        }

        // 3. Ultra-fast fallback heartbeat (200ms) to guarantee zero missed events
        watchTask = Task { [weak self] in
            guard let self else { return }
            while await self.isWatchingState() {
                await self.pollAppendedBytes(from: fileURL)
                try? await Task.sleep(nanoseconds: 200_000_000)
            }
        }

        return stream
    }

    public func stopWatching() {
        self.isWatching = false
        watchTask?.cancel()
        watchTask = nil
        dispatchSource?.cancel()
        dispatchSource = nil
        fileDescriptor = -1
        continuation?.finish()
        continuation = nil
    }

    private func isWatchingState() -> Bool {
        isWatching
    }

    private func readInitialTailBytes(from url: URL, currentSize: UInt64, maxLines: Int?) {
        guard let fileHandle = try? FileHandle(forReadingFrom: url) else { return }
        defer { try? fileHandle.close() }

        // If file is large and maxLines specified, sample the end of file (last ~32KB)
        let sampleSize: UInt64 = (maxLines != nil && currentSize > 32768) ? 32768 : currentSize
        let startOffset = currentSize - sampleSize
        fileHandle.seek(toFileOffset: startOffset)
        let data = fileHandle.readDataToEndOfFile()
        self.fileOffset = currentSize

        guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
        var lines = text.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        if let maxLines, lines.count > maxLines {
            lines = Array(lines.suffix(maxLines))
        }

        for line in lines {
            if let lineData = line.data(using: .utf8),
               let events = try? adapter.events(fromLine: lineData) {
                for event in events {
                    let redacted = redactor.redact(event: event)
                    continuation?.yield(redacted)
                }
            }
        }
    }

    private func pollAppendedBytes(from url: URL) {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let currentSize = attrs[.size] as? UInt64 else { return }

        // Reset if file was truncated
        if currentSize < fileOffset {
            fileOffset = 0
        }

        // Fast exit: if no new bytes were appended, skip opening FileHandle
        guard currentSize > fileOffset else { return }

        guard let fileHandle = try? FileHandle(forReadingFrom: url) else { return }
        defer { try? fileHandle.close() }

        // Seek to last known offset and read newly appended data
        fileHandle.seek(toFileOffset: fileOffset)
        let newData = fileHandle.readDataToEndOfFile()
        self.fileOffset = currentSize

        guard !newData.isEmpty, let text = String(data: newData, encoding: .utf8) else { return }

        let lines = text.components(separatedBy: "\n")
        for line in lines where !line.trimmingCharacters(in: .whitespaces).isEmpty {
            if let lineData = line.data(using: .utf8),
               let events = try? adapter.events(fromLine: lineData) {
                for event in events {
                    let redacted = redactor.redact(event: event)
                    continuation?.yield(redacted)
                }
            }
        }
    }
}
