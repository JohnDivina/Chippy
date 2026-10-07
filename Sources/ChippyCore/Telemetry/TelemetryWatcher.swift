import Foundation

/// Real-time actor monitoring active session transcripts on disk and streaming
/// parsed `AgentEvent` items over an AsyncStream.
public actor TelemetryWatcher {
    private var fileOffset: UInt64 = 0
    private var isWatching: Bool = false
    private var watchTask: Task<Void, Never>?
    private var continuation: AsyncStream<AgentEvent>.Continuation?

    private let adapter: any TranscriptAdapter
    private let redactor: Redactor

    public init(adapter: any TranscriptAdapter = AntigravityAdapter(), redactor: Redactor = Redactor()) {
        self.adapter = adapter
        self.redactor = redactor
    }

    /// Starts tailing the specified transcript file in real time.
    public func startWatching(fileURL: URL, readFromBeginning: Bool = true) -> AsyncStream<AgentEvent> {
        stopWatching()

        if !readFromBeginning {
            if let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
               let size = attrs[.size] as? UInt64 {
                self.fileOffset = size
            }
        } else {
            self.fileOffset = 0
        }

        self.isWatching = true

        let stream = AsyncStream<AgentEvent> { cont in
            self.continuation = cont
        }

        watchTask = Task { [weak self] in
            guard let self else { return }
            while await self.isWatchingState() {
                await self.pollAppendedBytes(from: fileURL)
                try? await Task.sleep(nanoseconds: 600_000_000) // Poll every 600ms
            }
        }

        return stream
    }

    public func stopWatching() {
        self.isWatching = false
        watchTask?.cancel()
        watchTask = nil
        continuation?.finish()
        continuation = nil
    }

    private func isWatchingState() -> Bool {
        isWatching
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
