import SwiftUI
import ChippyCore

/// Displays the stream of telemetry events with solid grey bubbles,
/// high contrast typography, and discrete indicators (anti-slop compliant).
public struct ActivityLogView: View {
    public let events: [AgentEvent]

    public init(events: [AgentEvent]) {
        self.events = events
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(events.enumerated()), id: \.offset) { index, event in
                        eventRow(for: event)
                            .id(index)
                    }
                }
                .padding(12)
            }
            .onChange(of: events.count) { _, newCount in
                if newCount > 0 {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo(newCount - 1, anchor: .bottom)
                    }
                }
            }
        }
        .background(ChippyTheme.surfacePrimary)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(ChippyTheme.borderSubtle, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private func eventRow(for event: AgentEvent) -> some View {
        HStack(alignment: .top, spacing: 8) {
            // Discrete solid status dot
            Circle()
                .fill(ChippyTheme.statusDot)
                .frame(width: 5, height: 5)
                .padding(.top, 6)

            VStack(alignment: .leading, spacing: 2) {
                Text(eventTitle(for: event))
                    .font(.system(size: 11, weight: .semibold, design: .default))
                    .foregroundColor(ChippyTheme.textPrimary)

                if let detail = eventDetail(for: event) {
                    Text(detail)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(ChippyTheme.textMuted)
                        .lineLimit(2)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(ChippyTheme.surfaceBubble)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(ChippyTheme.borderSubtle, lineWidth: 0.5)
        )
    }

    private func eventTitle(for event: AgentEvent) -> String {
        switch event {
        case .sessionStarted(_, let model, _):
            return "Session Started: \(model ?? "AI Model")"
        case .userPrompt:
            return "User Prompt Received"
        case .thinking:
            return "Reasoning & Planning"
        case .skillLoaded(_, let name):
            return "Skill Equipped: \(name)"
        case .fileRead(_, let path):
            return "File Read: \(URL(fileURLWithPath: path).lastPathComponent)"
        case .fileEdited(_, let path, let kind):
            let filename = URL(fileURLWithPath: path).lastPathComponent
            return kind == .created ? "File Created: \(filename)" : "File Modified: \(filename)"
        case .commandRun(_, let cmd):
            return "Shell Exec: \(cmd.components(separatedBy: " ").first ?? "command")"
        case .commandFinished:
            return "Command Completed"
        case .toolCall(_, let tool, _):
            switch tool {
            case .search: return "Codebase Search"
            case .ask: return "User Clarification"
            case .test: return "Test Execution"
            case .browser: return "Browser Inspection"
            case .bash: return "Terminal Operation"
            case .fileOperation: return "File System Operation"
            case .custom(let name): return "Tool: \(name)"
            }
        case .subagentSpawned(_, _, let task):
            return "Subagent Spawned: \(task)"
        case .subagentFinished:
            return "Subagent Finished"
        case .agentMessage:
            return "Model Response"
        case .decisionRequested(_, let question, _):
            let shortQ = question.count > 30 ? String(question.prefix(28)) + "…" : question
            return "Decision Needed: \(shortQ)"
        case .error(_, let msg, let reason):
            if reason == .quotaExceeded {
                return "Quota Exceeded: \(msg)"
            } else if reason == .rateLimited {
                return "Rate Limited: \(msg)"
            }
            return "Error: \(msg)"
        case .sessionEnded:
            return "Session Concluded"
        }
    }

    private func eventDetail(for event: AgentEvent) -> String? {
        switch event {
        case .userPrompt(let text):
            return text
        case .decisionRequested(_, let question, let options):
            return options.isEmpty ? question : "\(question) [\(options.joined(separator: ", "))]"
        case .fileRead(_, let path):
            return path
        case .fileEdited(_, let path, _):
            return path
        case .commandRun(_, let cmd):
            return cmd
        case .toolCall(_, _, let summary):
            return summary
        case .agentMessage(_, let text):
            return text.components(separatedBy: "\n").first
        case .error(_, let msg, _):
            return msg
        default:
            return nil
        }
    }
}
