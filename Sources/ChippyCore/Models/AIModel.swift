import Foundation

/// Represents the active AI Model manifested as the Sovereign.
/// As specified in the architecture, the model name is read dynamically
/// from data/telemetry rather than hardcoded.
public struct AIModel: Sendable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let provider: String?
    public let contextWindowTokens: Int?
    public let capabilities: [String]

    public init(
        id: String,
        name: String,
        provider: String? = nil,
        contextWindowTokens: Int? = nil,
        capabilities: [String] = []
    ) {
        self.id = id
        self.name = name
        self.provider = provider
        self.contextWindowTokens = contextWindowTokens
        self.capabilities = capabilities
    }

    /// Default fallback when waiting for telemetry detection.
    public static let unassigned = AIModel(
        id: "telemetry.pending",
        name: "Observing Model...",
        provider: "Auto-detected from transcript"
    )
}
