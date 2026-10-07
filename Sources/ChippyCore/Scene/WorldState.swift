import Foundation

/// A pure, deterministic snapshot of the diorama world state at any event index.
/// Used by ReplayEngine for instant seeking/scrubbing and state reconciliation.
public struct WorldState: Equatable, Sendable {
    public var familiarPositions: [FamiliarKind: GridPoint]
    public var activeWorkshops: Set<String>
    public var harborCrateFiles: [String: Int] // File path -> edit count
    public var activeModel: String
    public var lastThought: [FamiliarKind: String]
    public var totalEventsProcessed: Int

    public init(
        familiarPositions: [FamiliarKind: GridPoint] = [
            .sovereign: GridPoint(col: 10, row: 10),
            .weaver: GridPoint(col: 4, row: 14),
            .mason: GridPoint(col: 16, row: 14),
            .scout: GridPoint(col: 10, row: 4),
            .scribe: GridPoint(col: 4, row: 6),
            .sentinel: GridPoint(col: 16, row: 6)
        ],
        activeWorkshops: Set<String> = [],
        harborCrateFiles: [String: Int] = [:],
        activeModel: String = "Observing Model...",
        lastThought: [FamiliarKind: String] = [:],
        totalEventsProcessed: Int = 0
    ) {
        self.familiarPositions = familiarPositions
        self.activeWorkshops = activeWorkshops
        self.harborCrateFiles = harborCrateFiles
        self.activeModel = activeModel
        self.lastThought = lastThought
        self.totalEventsProcessed = totalEventsProcessed
    }

    /// Pure transition function reducing an event into a new state.
    public func reducing(_ event: AgentEvent) -> WorldState {
        var copy = self
        copy.totalEventsProcessed += 1

        switch event {
        case .sessionStarted(_, let model, _):
            copy.activeModel = model ?? "Observing Model..."
            copy.activeWorkshops.removeAll()
            copy.harborCrateFiles.removeAll()

        case .userPrompt:
            copy.familiarPositions[.sovereign] = GridPoint(col: 10, row: 10)

        case .thinking(let agentID):
            let kind = FamiliarKind.from(agentID: agentID)
            copy.lastThought[kind] = "Reasoning..."

        case .skillLoaded(_, let skillName):
            copy.activeWorkshops.insert(skillName)
            copy.familiarPositions[.scribe] = GridPoint(col: 4, row: 6)

        case .fileRead(let agentID, let path):
            let kind = FamiliarKind.from(agentID: agentID)
            copy.familiarPositions[kind] = GridPoint(col: 10, row: 4) // Harbor/Scout
            copy.harborCrateFiles[path, default: 0] += 0

        case .fileEdited(let agentID, let path, _):
            let kind = FamiliarKind.from(agentID: agentID)
            let route = PathRouter.route(filePath: path)
            switch route.district {
            case .grandAtelier: copy.familiarPositions[kind] = GridPoint(col: 4, row: 14)
            case .engineCore: copy.familiarPositions[kind] = GridPoint(col: 16, row: 14)
            case .scriptorium: copy.familiarPositions[kind] = GridPoint(col: 4, row: 6)
            case .ironBastion: copy.familiarPositions[kind] = GridPoint(col: 16, row: 6)
            default: copy.familiarPositions[kind] = GridPoint(col: 10, row: 10)
            }
            copy.harborCrateFiles[path, default: 0] += 1

        case .commandRun(let agentID, _):
            let kind = FamiliarKind.from(agentID: agentID)
            copy.familiarPositions[kind] = GridPoint(col: 16, row: 6) // Sentinel

        case .toolCall(let agentID, let toolKind, _):
            let kind = FamiliarKind.from(agentID: agentID)
            switch toolKind {
            case .browser: copy.familiarPositions[kind] = GridPoint(col: 10, row: 4)
            case .bash: copy.familiarPositions[kind] = GridPoint(col: 16, row: 6)
            default: break
            }

        case .sessionEnded:
            copy.activeWorkshops.removeAll()

        default:
            break
        }

        return copy
    }
}
