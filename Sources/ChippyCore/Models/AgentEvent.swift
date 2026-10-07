import Foundation

/// Defines file edit operations observed in telemetry.
public enum EditKind: String, Sendable, Equatable, Codable {
    case created
    case modified
    case deleted
}

/// Identifies categories of tool actions.
public enum ToolKind: Sendable, Equatable, Hashable, Codable {
    case search
    case test
    case ask
    case browser
    case bash
    case fileOperation
    case custom(String)
}

/// Categorizes failure reasons observed in telemetry.
public enum ErrorReason: String, Sendable, Equatable, Codable {
    case generic
    case quotaExceeded
    case rateLimited
    case permissionDenied
    case toolExecutionFailed
}

/// The normalized event stream model at the heart of Chippy.
/// Neither the UI HUD nor the SpriteKit scene parse raw transcripts;
/// all inputs are normalized into `AgentEvent` values.
public enum AgentEvent: Sendable, Equatable {
    case sessionStarted(sessionID: String, model: String?, startedAt: Date)
    case userPrompt(text: String)
    case thinking(agentID: String)
    case toolCall(agentID: String, tool: ToolKind, summary: String)
    case skillLoaded(agentID: String, skillName: String)
    case fileRead(agentID: String, path: String)
    case fileEdited(agentID: String, path: String, kind: EditKind)
    case commandRun(agentID: String, command: String)
    case commandFinished(agentID: String, exitCode: Int32?)
    case subagentSpawned(parentID: String, childID: String, task: String)
    case subagentFinished(childID: String)
    case agentMessage(agentID: String, text: String)
    case error(agentID: String, message: String, reason: ErrorReason)
    case sessionEnded(sessionID: String)

    public static func error(agentID: String, message: String) -> AgentEvent {
        .error(agentID: agentID, message: message, reason: .generic)
    }
}
