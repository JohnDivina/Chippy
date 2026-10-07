import Foundation

/// Protocol defining a transcript parser capable of adapting raw agent logs
/// into normalized `AgentEvent` streams.
public protocol TranscriptAdapter: Sendable {
    /// Unique identifier for this adapter (e.g. "antigravity", "claude-code").
    static var id: String { get }

    /// Returns whether this adapter can parse the specified file.
    func canHandle(fileAt url: URL) -> Bool

    /// Parses a single raw line (usually JSON) into zero or more `AgentEvent` objects.
    /// Unknown or unhandled entries must return an empty array without throwing.
    func events(fromLine line: Data) throws -> [AgentEvent]
}
