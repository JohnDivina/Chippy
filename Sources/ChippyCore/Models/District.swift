import Foundation

/// Canonical identifiers for island districts.
public enum DistrictID: String, Sendable, Equatable, Hashable, CaseIterable, Codable {
    case highCouncil = "high_council"
    case ironBastion = "iron_bastion"
    case grandAtelier = "grand_atelier"
    case engineCore = "engine_core"
    case scriptorium = "scriptorium"
    case wanderersMarket = "wanderers_market"

    public var displayName: String {
        switch self {
        case .highCouncil: return "The High Council"
        case .ironBastion: return "The Iron Bastion"
        case .grandAtelier: return "The Grand Atelier"
        case .engineCore: return "The Engine Core"
        case .scriptorium: return "The Scriptorium"
        case .wanderersMarket: return "Wanderer's Market"
        }
    }
}

/// Represents an island district where specialized workshops cluster.
public struct District: Sendable, Identifiable, Equatable {
    public let id: DistrictID
    public let displayName: String
    public let icon: String
    public let workshopName: String
    public let residentFamiliars: [FamiliarKind]
    public let description: String

    public init(
        id: DistrictID,
        displayName: String,
        icon: String,
        workshopName: String,
        residentFamiliars: [FamiliarKind],
        description: String
    ) {
        self.id = id
        self.displayName = displayName
        self.icon = icon
        self.workshopName = workshopName
        self.residentFamiliars = residentFamiliars
        self.description = description
    }

    /// The predefined districts composing the island diorama.
    public static let allDistricts: [District] = [
        District(
            id: .highCouncil,
            displayName: "The High Council",
            icon: "🏛️",
            workshopName: "War Table & Spire",
            residentFamiliars: [.sovereign, .scribe],
            description: "High strategy, planning, coordination, and reasoning sanctum."
        ),
        District(
            id: .ironBastion,
            displayName: "The Iron Bastion",
            icon: "🛡️",
            workshopName: "Fortress Forge & Gate",
            residentFamiliars: [.sentinel, .arbiter],
            description: "Defense, vulnerability auditing, automated testing, and verification."
        ),
        District(
            id: .grandAtelier,
            displayName: "The Grand Atelier",
            icon: "🎨",
            workshopName: "The Weaver's Loom",
            residentFamiliars: [.weaver],
            description: "User interfaces, responsive layout, visual design, and asset craft."
        ),
        District(
            id: .engineCore,
            displayName: "The Engine Core",
            icon: "⚙️",
            workshopName: "The Clockwork Foundry",
            residentFamiliars: [.mason],
            description: "Databases, API infrastructure, systems engineering, and shell operations."
        ),
        District(
            id: .scriptorium,
            displayName: "The Scriptorium",
            icon: "📜",
            workshopName: "The Archive",
            residentFamiliars: [.scribe],
            description: "Documentation templates, skill creation, and MCP builders."
        ),
        District(
            id: .wanderersMarket,
            displayName: "The Wanderer's Market",
            icon: "🧭",
            workshopName: "Open Stalls",
            residentFamiliars: [.scout],
            description: "Community stalls welcoming newly discovered and custom skills."
        )
    ]
}
