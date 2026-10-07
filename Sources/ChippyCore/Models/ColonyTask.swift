import Foundation

/// State of a colony quest or workbench task in the Kanban board.
public enum ColonyTaskState: String, Sendable, Codable, CaseIterable {
    case planned = "Planned"
    case inProgress = "In Progress"
    case completed = "Completed"
}

/// A discrete task tracked on the Colony Quest Board.
public struct ColonyTask: Identifiable, Sendable, Equatable, Codable {
    public let id: UUID
    public var title: String
    public var category: String
    public var state: ColonyTaskState
    public var assignedFamiliar: FamiliarKind
    public var districtID: DistrictID
    public var timestamp: Date
    public var completedAt: Date?

    public init(
        id: UUID = UUID(),
        title: String,
        category: String = "Engineering",
        state: ColonyTaskState = .inProgress,
        assignedFamiliar: FamiliarKind = .sovereign,
        districtID: DistrictID = .highCouncil,
        timestamp: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.state = state
        self.assignedFamiliar = assignedFamiliar
        self.districtID = districtID
        self.timestamp = timestamp
        self.completedAt = completedAt
    }
}

/// Pure functional task reducer updating the colony quest board from telemetry events.
public struct ColonyTaskManager: Sendable {
    public static let maxTrackedTasks = 60

    public init() {}

    /// Reduces an incoming `AgentEvent` against the existing task list, returning updated tasks.
    public func process(event: AgentEvent, currentTasks: [ColonyTask]) -> [ColonyTask] {
        var tasks = currentTasks

        switch event {
        case .sessionStarted(_, let model, _):
            tasks.append(ColonyTask(
                title: "Initialize session: \(model ?? "AI Council")",
                category: "Orchestration",
                state: .completed,
                assignedFamiliar: .sovereign,
                districtID: .highCouncil,
                completedAt: Date()
            ))

        case .userPrompt(let text):
            let shortPrompt = text.components(separatedBy: "\n").first ?? text
            let title = shortPrompt.count > 60 ? String(shortPrompt.prefix(57)) + "…" : shortPrompt
            tasks.append(ColonyTask(
                title: "Quest: \(title)",
                category: "Goal",
                state: .inProgress,
                assignedFamiliar: .sovereign,
                districtID: .highCouncil
            ))

        case .subagentSpawned(_, _, let task):
            let shortTask = task.count > 55 ? String(task.prefix(52)) + "…" : task
            tasks.append(ColonyTask(
                title: "Delegate: \(shortTask)",
                category: "Subagent",
                state: .inProgress,
                assignedFamiliar: .sentinel,
                districtID: .ironBastion
            ))

        case .subagentFinished:
            if let idx = tasks.lastIndex(where: { $0.assignedFamiliar == .sentinel && $0.state == .inProgress }) {
                tasks[idx].state = .completed
                tasks[idx].completedAt = Date()
            }

        case .fileEdited(_, let path, let kind):
            let filename = URL(fileURLWithPath: path).lastPathComponent
            let route = PathRouter.route(filePath: path)
            let action = kind == .created ? "Create" : "Craft"
            tasks.append(ColonyTask(
                title: "\(action) \(filename)",
                category: "Artifact",
                state: .inProgress,
                assignedFamiliar: route.familiar,
                districtID: route.district
            ))

        case .commandRun(_, let command):
            let shortCmd = command.components(separatedBy: " ").first ?? "exec"
            tasks.append(ColonyTask(
                title: "Exec: \(shortCmd)",
                category: "Terminal",
                state: .inProgress,
                assignedFamiliar: .mason,
                districtID: .engineCore
            ))

        case .commandFinished:
            if let idx = tasks.lastIndex(where: { $0.assignedFamiliar == .mason && $0.state == .inProgress }) {
                tasks[idx].state = .completed
                tasks[idx].completedAt = Date()
            }

        case .toolCall(_, let tool, let summary):
            let familiar: FamiliarKind
            let district: DistrictID
            switch tool {
            case .search:
                familiar = .scout
                district = .wanderersMarket
            case .test:
                familiar = .sentinel
                district = .ironBastion
            case .ask:
                familiar = .sovereign
                district = .highCouncil
            default:
                familiar = .scout
                district = .wanderersMarket
            }
            let shortSummary = summary.count > 50 ? String(summary.prefix(47)) + "…" : summary
            tasks.append(ColonyTask(
                title: shortSummary,
                category: "Tool",
                state: .inProgress,
                assignedFamiliar: familiar,
                districtID: district
            ))

        case .decisionRequested(_, let question, _):
            let shortQ = question.count > 55 ? String(question.prefix(52)) + "…" : question
            tasks.append(ColonyTask(
                title: "Decision: \(shortQ)",
                category: "Podium",
                state: .inProgress,
                assignedFamiliar: .sovereign,
                districtID: .highCouncil
            ))

        case .agentMessage:
            // Complete any active goal quests
            if let idx = tasks.lastIndex(where: { $0.category == "Goal" && $0.state == .inProgress }) {
                tasks[idx].state = .completed
                tasks[idx].completedAt = Date()
            }

        case .error(_, let msg, _):
            let shortErr = msg.count > 45 ? String(msg.prefix(42)) + "…" : msg
            tasks.append(ColonyTask(
                title: "Alert: \(shortErr)",
                category: "Incident",
                state: .completed,
                assignedFamiliar: .sovereign,
                districtID: .highCouncil,
                completedAt: Date()
            ))

        case .thinking, .fileRead, .skillLoaded, .sessionEnded:
            break
        }

        // Keep maximum capped tasks
        if tasks.count > Self.maxTrackedTasks {
            tasks.removeFirst(tasks.count - Self.maxTrackedTasks)
        }

        return tasks
    }
}
