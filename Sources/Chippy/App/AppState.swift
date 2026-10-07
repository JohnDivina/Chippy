import SwiftUI
import ChippyCore

/// Represents an active decision presented at the Town Hall Decision Podium.
public struct DecisionItem: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let agentID: String
    public let question: String
    public let options: [String]
    public let timestamp: Date

    public init(id: UUID = UUID(), agentID: String, question: String, options: [String] = [], timestamp: Date = Date()) {
        self.id = id
        self.agentID = agentID
        self.question = question
        self.options = options
        self.timestamp = timestamp
    }
}

/// Identifies a target crate file for detailed code and diff inspection.
public struct DiffTarget: Identifiable, Equatable {
    public var id: String { path }
    public let path: String
    public let count: Int

    public init(path: String, count: Int) {
        self.path = path
        self.count = count
    }
}

/// Centralized `@Observable` application state for Chippy.
/// Manages live mode, observed model, skills, session history,
/// interactive quest board, decision podium, and ring-buffered events (max 500).
@Observable
@MainActor
public final class AppState {
    public var activeModelName: String = "Observing Model..."
    public var isPlaying: Bool = false
    public var currentSpeed: PlaybackSpeed = .normal
    public var currentProgress: Int = 0
    public var totalEvents: Int = 0
    public var loadedSkills: [SkillWorkshop] = []
    public var isLiveAntigravityMode: Bool = true
    public var latestResponse: String? = nil
    public var isPinnedOnTop: Bool = false
    public var activeSessionID: String? = nil
    public var availableSessions: [SessionInfo] = []
    public var promptSubmittedFromChippy: Bool = false
    public var showSettings: Bool = false
    public var showChronicle: Bool = false
    public var showTeachingMode: Bool = true
    public var hasUnreadResponse: Bool = false

    // AgentCraft Features
    public var pendingDecision: DecisionItem? = nil
    public var showQuestBoard: Bool = false
    public var inspectedEntity: InspectedEntity? = nil
    public var inspectingDiff: DiffTarget? = nil
    public var colonyTasks: [ColonyTask] = []

    private let taskManager = ColonyTaskManager()

    // Ring-buffered event log (max 500 events to prevent unbounded memory growth)
    public private(set) var eventLog: [AgentEvent] = []

    public init() {}

    /// Appends an event to the ring buffer and updates the colony quest manager.
    public func appendEvent(_ event: AgentEvent) {
        eventLog.append(event)
        if eventLog.count > 500 {
            eventLog.removeFirst(eventLog.count - 500)
        }

        // Update Quest Board tasks
        colonyTasks = taskManager.process(event: event, currentTasks: colonyTasks)

        // Process Decision Podium events
        if case .decisionRequested(let agentID, let question, let options) = event {
            self.pendingDecision = DecisionItem(agentID: agentID, question: question, options: options)
            SoundEffects.shared.playDecisionAlert()
        }

        // Sound effects for completed milestones
        if case .commandFinished = event {
            SoundEffects.shared.playQuestCompleted()
        } else if case .fileEdited = event {
            SoundEffects.shared.playCrateCrafted()
        }
    }

    /// Clears the event buffer and resets tasks for the active session.
    public func clearEvents() {
        eventLog.removeAll()
        colonyTasks.removeAll()
        pendingDecision = nil
        inspectingDiff = nil
    }
}
