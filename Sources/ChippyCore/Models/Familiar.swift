import Foundation

/// The distinct roles of animated familiars in Chippy's world.
public enum FamiliarKind: String, Sendable, Equatable, Hashable, CaseIterable, Codable {
    case sovereign
    case scout
    case scribe
    case mason
    case weaver
    case sentinel
    case arbiter

    public var displayName: String {
        switch self {
        case .sovereign: return "The Sovereign"
        case .scout: return "The Scout"
        case .scribe: return "The Scribe"
        case .mason: return "The Mason"
        case .weaver: return "The Weaver"
        case .sentinel: return "The Sentinel"
        case .arbiter: return "The Arbiter"
        }
    }

    public var roleDescription: String {
        switch self {
        case .sovereign: return "Lead model overseeing strategy and coordination from the High Citadel."
        case .scout: return "Explorer responsible for codebase search, web queries, and file discovery."
        case .scribe: return "Scholar managing plan writing, markdown documentation, and skill scrolls."
        case .mason: return "Builder crafting backend architectures, databases, and executing shell tasks."
        case .weaver: return "Artisan weaving user interfaces, styling, and visual assets."
        case .sentinel: return "Guardian running automated test suites, browser checks, and security audits."
        case .arbiter: return "Inspector performing code review checklists and verifying changes."
        }
    }
}

/// The current activity state of a familiar in the diorama.
public enum FamiliarState: Sendable, Equatable {
    case idle
    case walking(targetLocation: String)
    case working(task: String)
    case thinking(thought: String)
    case resting
    case error(message: String)
}

/// A living creature instance operating within the island scene.
public struct Familiar: Sendable, Identifiable, Equatable {
    public let id: String
    public let kind: FamiliarKind
    public var state: FamiliarState
    public var assignedDistrictID: DistrictID?

    public init(
        id: String,
        kind: FamiliarKind,
        state: FamiliarState = .idle,
        assignedDistrictID: DistrictID? = nil
    ) {
        self.id = id
        self.kind = kind
        self.state = state
        self.assignedDistrictID = assignedDistrictID
    }
}
