import SwiftUI
import ChippyCore

/// Centralized `@Observable` application state for Chippy.
/// Manages live mode, observed model, skills, session history, and ring-buffered events (max 500).
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

    // Ring-buffered event log (max 500 events to prevent unbounded memory growth)
    public private(set) var eventLog: [AgentEvent] = []

    public init() {}

    /// Appends an event to the ring buffer, capping at 500 items.
    public func appendEvent(_ event: AgentEvent) {
        eventLog.append(event)
        if eventLog.count > 500 {
            eventLog.removeFirst(eventLog.count - 500)
        }
    }

    /// Clears the event buffer.
    public func clearEvents() {
        eventLog.removeAll()
    }
}
