import SwiftUI
import ChippyCore

/// Floating prompt chatbox allowing users to dispatch goals, quests, and natural language prompts
/// directly to Chippy's colony.
public struct PromptChatboxView: View {
    @Binding public var promptText: String
    public let isLiveMode: Bool
    public var onToggleLiveMode: () -> Void
    public var onSubmitPrompt: (String) -> Void

    @FocusState private var isFieldFocused: Bool

    public init(
        promptText: Binding<String>,
        isLiveMode: Bool,
        onToggleLiveMode: @escaping () -> Void,
        onSubmitPrompt: @escaping (String) -> Void
    ) {
        self._promptText = promptText
        self.isLiveMode = isLiveMode
        self.onToggleLiveMode = onToggleLiveMode
        self.onSubmitPrompt = onSubmitPrompt
    }

    public var body: some View {
        HStack(spacing: 10) {
            // Mode toggle pill (Live Antigravity vs Replay)
            Button(action: onToggleLiveMode) {
                HStack(spacing: 5) {
                    Circle()
                        .fill(ChippyTheme.statusDot)
                        .opacity(isLiveMode ? 1.0 : 0.45)
                        .frame(width: 5, height: 5)
                    Text(isLiveMode ? "Antigravity Live" : "Replay Mode")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(ChippyTheme.textPrimary)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 7)
                .background(ChippyTheme.surfacePrimary)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(ChippyTheme.borderSubtle, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            // Text input field
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11))
                    .foregroundColor(ChippyTheme.textMuted)

                TextField("Assign a quest to Chippy (e.g. 'Audit database queries for RLS', 'Build portfolio')…", text: $promptText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .focused($isFieldFocused)
                    .onSubmit {
                        submit()
                    }

                if !promptText.isEmpty {
                    Button(action: submit) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(ChippyTheme.accentSolid)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(ChippyTheme.surfaceBubble)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isFieldFocused ? ChippyTheme.textPrimary : ChippyTheme.borderSubtle, lineWidth: 1)
            )
        }
        .padding(6)
        .background(ChippyTheme.surfacePrimary)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ChippyTheme.borderSubtle, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 3)
    }

    private func submit() {
        let trimmed = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onSubmitPrompt(trimmed)
        promptText = ""
    }
}
