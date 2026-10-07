import Foundation

/// Buffers incoming data chunks and yields only complete, newline-terminated lines.
/// Any incomplete trailing fragment is retained across calls until its terminating newline arrives.
public struct LineAssembler: Sendable {
    private var buffer = Data()

    public init() {}

    /// Ingests newly read data and returns an array of complete lines (as UTF-8 strings).
    public mutating func ingest(_ data: Data) -> [String] {
        guard !data.isEmpty else { return [] }
        buffer.append(data)

        // Find the index of the last newline byte (0x0A)
        guard let lastNewlineIndex = buffer.lastIndex(of: 0x0A) else {
            // No newline found yet, retain all bytes in buffer
            return []
        }

        let completeChunk = buffer.subdata(in: 0..<lastNewlineIndex)
        // Retain remaining bytes (excluding the last newline itself)
        if lastNewlineIndex + 1 < buffer.count {
            buffer = buffer.subdata(in: (lastNewlineIndex + 1)..<buffer.count)
        } else {
            buffer.removeAll(keepingCapacity: true)
        }

        guard let text = String(data: completeChunk, encoding: .utf8) else {
            return []
        }

        return text
            .components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    /// Resets any buffered fragments (e.g. on file truncation or file rotation).
    public mutating func reset() {
        buffer.removeAll(keepingCapacity: false)
    }

    /// Returns true if the assembler currently has pending uncompleted bytes.
    public var hasPendingBytes: Bool {
        !buffer.isEmpty
    }
}
