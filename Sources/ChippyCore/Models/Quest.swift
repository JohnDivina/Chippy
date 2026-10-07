import Foundation

/// Status of a quest initiated by the user.
public enum QuestStatus: String, Sendable, Equatable, Codable {
    case draft
    case inProgress
    case completed
    case failed
    case cancelled
}

/// A discrete step or milestone within a quest.
public struct QuestStep: Sendable, Identifiable, Equatable {
    public let id: String
    public let title: String
    public var isCompleted: Bool
    public var familiarAssigned: FamiliarKind?

    public init(id: String, title: String, isCompleted: Bool = false, familiarAssigned: FamiliarKind? = nil) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.familiarAssigned = familiarAssigned
    }
}

/// A structured development goal configured in Director Mode or observed in telemetry.
public struct Quest: Sendable, Identifiable, Equatable {
    public let id: UUID
    public let goal: String
    public let targetDirectory: URL
    public var status: QuestStatus
    public var steps: [QuestStep]
    public var createdAt: Date
    public var startedAt: Date?
    public var finishedAt: Date?

    public init(
        id: UUID = UUID(),
        goal: String,
        targetDirectory: URL,
        status: QuestStatus = .draft,
        steps: [QuestStep] = [],
        createdAt: Date = Date(),
        startedAt: Date? = nil,
        finishedAt: Date? = nil
    ) {
        self.id = id
        self.goal = goal
        self.targetDirectory = targetDirectory
        self.status = status
        self.steps = steps
        self.createdAt = createdAt
        self.startedAt = startedAt
        self.finishedAt = finishedAt
    }
}
