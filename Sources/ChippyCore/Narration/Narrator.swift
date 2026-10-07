import Foundation

/// Generates human-readable, plain-English captions for events in real time.
/// Powers the Teaching Mode subtitles and session understanding for non-engineers.
public struct Narrator: Sendable {
    public init() {}

    /// Formats an AgentEvent into an educational narrative caption.
    public func narrate(event: AgentEvent) -> String {
        switch event {
        case .sessionStarted(_, let model, _):
            let modelName = model ?? "Active Model"
            return "Council convened with observed model \(modelName)."

        case .userPrompt(let text):
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            let snippet = trimmed.count > 50 ? String(trimmed.prefix(47)) + "..." : trimmed
            return "New quest received: \"\(snippet)\""

        case .thinking:
            return "The Sovereign is contemplating the strategy and reasoning through the solution."

        case .skillLoaded(_, let skillName):
            return "The Scribe referenced the '\(skillName)' skill codex at the Scriptorium."

        case .fileRead(_, let path):
            let filename = URL(fileURLWithPath: path).lastPathComponent
            return "The Scout is inspecting '\(filename)' at the Harbor."

        case .fileEdited(_, let path, _):
            let filename = URL(fileURLWithPath: path).lastPathComponent
            let route = PathRouter.route(filePath: path)
            switch route.district {
            case .grandAtelier:
                return "The Weaver is styling UI component '\(filename)' at the Grand Atelier."
            case .ironBastion:
                return "The Sentinel is strengthening tests in '\(filename)' at the Iron Bastion."
            case .scriptorium:
                return "The Scribe is documenting changes in '\(filename)' at the Scriptorium."
            default:
                return "The Mason is forging core code in '\(filename)' at the Engine Core."
            }

        case .commandRun(_, let command):
            let snippet = command.count > 40 ? String(command.prefix(37)) + "..." : command
            return "The Sentinel executed `\(snippet)` in the terminal."

        case .commandFinished(_, let exitCode):
            if let exitCode = exitCode {
                return exitCode == 0 ? "Terminal operation succeeded." : "Terminal command finished with exit code \(exitCode)."
            }
            return "Terminal operation concluded."

        case .toolCall(_, _, let summary):
            return summary.isEmpty ? "The council invoked an external capability." : summary

        case .subagentSpawned(_, _, let task):
            let snippet = task.count > 45 ? String(task.prefix(42)) + "..." : task
            return "Dispatched a specialized subagent: \(snippet)"

        case .subagentFinished:
            return "Subagent concluded its mission and reported back to the Citadel."

        case .agentMessage:
            return "The Sovereign presented the Council Dispatch answer."

        case .decisionRequested(_, let question, _):
            let snippet = question.count > 45 ? String(question.prefix(42)) + "..." : question
            return "The Sovereign stepped to the podium: \(snippet)"

        case .error(_, let msg, let reason):
            if reason == .quotaExceeded {
                return "Antigravity quota limit encountered: \(msg)"
            } else if reason == .rateLimited {
                return "Rate limit reached: pausing momentarily."
            }
            return "Obstacle encountered: \(msg)"

        case .sessionEnded:
            return "The council concluded all tasks for this session."
        }
    }
}
