import SwiftUI
import AppKit
import ChippyCore

/// Computes summary statistics from an array of AgentEvents.
public struct SessionChronicle: Sendable {
    public let promptCount: Int
    public let filesTouched: [String]
    public let commandsRun: Int
    public let commandFailures: Int
    public let skillsUsed: Set<String>
    public let subagentsSpawned: Int
    public let errorCount: Int
    public let durationString: String

    public init(events: [AgentEvent], startTime: Date = Date(), endTime: Date = Date()) {
        var prompts = 0
        var touchedFiles = Set<String>()
        var commands = 0
        var failures = 0
        var skills = Set<String>()
        var subagents = 0
        var errors = 0

        for event in events {
            switch event {
            case .userPrompt:
                prompts += 1
            case .fileRead(_, let path), .fileEdited(_, let path, _):
                touchedFiles.insert(path)
            case .commandRun:
                commands += 1
            case .commandFinished(_, let exitCode):
                if exitCode != 0 { failures += 1 }
            case .skillLoaded(_, let name):
                skills.insert(name)
            case .subagentSpawned:
                subagents += 1
            case .error:
                errors += 1
            default:
                break
            }
        }

        self.promptCount = prompts
        self.filesTouched = Array(touchedFiles)
        self.commandsRun = commands
        self.commandFailures = failures
        self.skillsUsed = skills
        self.subagentsSpawned = subagents
        self.errorCount = errors

        let elapsed = max(1, Int(endTime.timeIntervalSince(startTime)))
        let minutes = elapsed / 60
        let seconds = elapsed % 60
        self.durationString = "\(minutes)m \(seconds)s"
    }

    /// Formats the chronicle as clean markdown for copying.
    public func toMarkdown(sessionTitle: String) -> String {
        return """
        # 📜 Session Chronicle: \(sessionTitle)
        - **Prompts Given:** \(promptCount)
        - **Files Touched:** \(filesTouched.count)
        - **Terminal Commands:** \(commandsRun) (\(commandFailures) failed)
        - **Skills Referenced:** \(skillsUsed.isEmpty ? "None" : skillsUsed.joined(separator: ", "))
        - **Subagents Spawned:** \(subagentsSpawned)
        - **Errors Encountered:** \(errorCount)
        """
    }
}

/// Modal card presenting the session chronicle to the user.
/// Conforms to anti-slop guidelines: solid dark surfaces, crisp borders.
public struct ChronicleView: View {
    public let chronicle: SessionChronicle
    public let sessionTitle: String
    public var onClose: () -> Void

    @State private var copied: Bool = false

    public init(chronicle: SessionChronicle, sessionTitle: String, onClose: @escaping () -> Void) {
        self.chronicle = chronicle
        self.sessionTitle = sessionTitle
        self.onClose = onClose
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("📜 Session Chronicle")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(ChippyTheme.textPrimary)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(ChippyTheme.textMuted)
                        .padding(6)
                        .background(ChippyTheme.surfaceBubble)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            Text("Summary of actions and achievements in session: \(sessionTitle)")
                .font(.system(size: 11))
                .foregroundColor(ChippyTheme.textMuted)

            Divider().background(ChippyTheme.borderSubtle)

            // Grid of stats
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                statCard(label: "Quests / Prompts", value: "\(chronicle.promptCount)", icon: "bubble.left.and.bubble.right.fill")
                statCard(label: "Files Touched", value: "\(chronicle.filesTouched.count)", icon: "doc.fill")
                statCard(label: "Commands Executed", value: "\(chronicle.commandsRun)", icon: "terminal.fill")
                statCard(label: "Subagents Spawned", value: "\(chronicle.subagentsSpawned)", icon: "person.2.fill")
                statCard(label: "Skills Consulted", value: "\(chronicle.skillsUsed.count)", icon: "book.fill")
                statCard(label: "Obstacles / Errors", value: "\(chronicle.errorCount)", icon: "exclamationmark.triangle.fill")
            }

            Divider().background(ChippyTheme.borderSubtle)

            // Action buttons
            HStack {
                Button(action: copyToClipboard) {
                    HStack(spacing: 6) {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        Text(copied ? "Copied Markdown" : "Copy Markdown")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(ChippyTheme.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(ChippyTheme.surfaceBubble)
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(ChippyTheme.borderSubtle, lineWidth: 1))
                }
                .buttonStyle(.plain)

                Spacer()

                Button("Done", action: onClose)
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(ChippyTheme.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(ChippyTheme.surfaceBubble)
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(ChippyTheme.borderSubtle, lineWidth: 1))
            }
        }
        .padding(20)
        .frame(width: 460)
        .background(ChippyTheme.surfacePrimary)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(ChippyTheme.borderSubtle, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.35), radius: 20, x: 0, y: 10)
    }

    private func statCard(label: String, value: String, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(ChippyTheme.textMuted)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(ChippyTheme.textPrimary)
                Text(label)
                    .font(.system(size: 10))
                    .foregroundColor(ChippyTheme.textMuted)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ChippyTheme.surfaceBubble)
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(ChippyTheme.borderSubtle, lineWidth: 0.5))
    }

    private func copyToClipboard() {
        let md = chronicle.toMarkdown(sessionTitle: sessionTitle)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(md, forType: .string)
        withAnimation { copied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { copied = false }
        }
    }
}
