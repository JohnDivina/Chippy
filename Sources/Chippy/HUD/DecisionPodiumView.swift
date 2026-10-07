import SwiftUI
import ChippyCore

/// Town Hall Decision Podium card presenting human-in-the-loop choices
/// from `ask_question` with selectable options and direct AppleScript dispatch.
public struct DecisionPodiumView: View {
    public let decision: DecisionItem
    public var onSubmit: (String) -> Void
    public var onDismiss: () -> Void

    @State private var selectedOption: String? = nil
    @State private var customText: String = ""

    public init(
        decision: DecisionItem,
        onSubmit: @escaping (String) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.decision = decision
        self.onSubmit = onSubmit
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 8) {
                Text("🏛️")
                    .font(.system(size: 16))

                VStack(alignment: .leading, spacing: 2) {
                    Text("DECISION PODIUM")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(ChippyTheme.textMuted)

                    Text("The Sovereign Requests Your Guidance")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(ChippyTheme.textPrimary)
                }

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(ChippyTheme.textMuted)
                        .padding(5)
                        .background(ChippyTheme.surfaceBubble)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            Divider().background(ChippyTheme.borderSubtle)

            // Question Box
            VStack(alignment: .leading, spacing: 6) {
                Text("QUESTION")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(ChippyTheme.textMuted)

                Text(decision.question)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(ChippyTheme.textPrimary)
                    .lineSpacing(3)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(ChippyTheme.surfaceBubble)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(ChippyTheme.borderSubtle, lineWidth: 1))
            }

            // Selectable Options (if provided)
            if !decision.options.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("CHOOSE AN OPTION")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(ChippyTheme.textMuted)

                    VStack(spacing: 6) {
                        ForEach(decision.options, id: \.self) { option in
                            Button(action: {
                                selectedOption = (selectedOption == option ? nil : option)
                            }) {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(selectedOption == option ? ChippyTheme.accentSolid : Color.clear)
                                        .frame(width: 8, height: 8)
                                        .overlay(Circle().stroke(ChippyTheme.borderSubtle, lineWidth: 1))

                                    Text(option)
                                        .font(.system(size: 11, weight: selectedOption == option ? .semibold : .regular))
                                        .foregroundColor(ChippyTheme.textPrimary)

                                    Spacer()
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(selectedOption == option ? ChippyTheme.surfaceBubble.opacity(0.8) : ChippyTheme.surfaceBubble)
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(selectedOption == option ? ChippyTheme.textPrimary : ChippyTheme.borderSubtle, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            // Custom Response / Instructions
            VStack(alignment: .leading, spacing: 6) {
                Text("OR WRITE CUSTOM INSTRUCTIONS")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(ChippyTheme.textMuted)

                TextField("Type your response here...", text: $customText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundColor(ChippyTheme.textPrimary)
                    .padding(10)
                    .background(ChippyTheme.surfaceBubble)
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(ChippyTheme.borderSubtle, lineWidth: 1))
                    .onSubmit { submitDecision() }
            }

            // Action Buttons
            HStack(spacing: 10) {
                Button(action: onDismiss) {
                    Text("Snooze")
                        .font(.system(size: 11))
                        .foregroundColor(ChippyTheme.textMuted)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(ChippyTheme.surfaceBubble)
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(ChippyTheme.borderSubtle, lineWidth: 1))
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: submitDecision) {
                    HStack(spacing: 6) {
                        Text("Dispatch to Antigravity")
                            .font(.system(size: 11, weight: .semibold))
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundColor(ChippyTheme.surfacePrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(ChippyTheme.accentSolid)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .disabled(selectedOption == nil && customText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity((selectedOption == nil && customText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? 0.45 : 1.0)
            }
        }
        .padding(18)
        .frame(width: 440)
        .background(ChippyTheme.surfacePrimary)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(ChippyTheme.borderSubtle, lineWidth: 1))
        .shadow(color: Color.black.opacity(0.35), radius: 16, x: 0, y: 8)
    }

    private func submitDecision() {
        var parts: [String] = []
        if let opt = selectedOption {
            parts.append(opt)
        }
        let trimmedCustom = customText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedCustom.isEmpty {
            parts.append(trimmedCustom)
        }
        guard !parts.isEmpty else { return }
        let answer = parts.joined(separator: " - ")
        onSubmit(answer)
    }
}
