import SwiftUI
import ChippyCore

/// Popover allowing users to view telemetry model status and switch active orchestrator models.
public struct ModelSelectorView: View {
    @Binding public var activeModelName: String
    public let isConnectedToLiveAntigravity: Bool
    public var onSelectModel: (String) -> Void
    public var onClose: () -> Void

    private let availableModels: [String] = [
        "Gemini 3.8 Flash (High)",
        "Claude 3.7 Sonnet (Thinking)",
        "GPT-4o (Frontier)",
        "DeepSeek-V3",
        "Ollama (Local Llama 3.3)"
    ]

    public init(
        activeModelName: Binding<String>,
        isConnectedToLiveAntigravity: Bool,
        onSelectModel: @escaping (String) -> Void,
        onClose: @escaping () -> Void
    ) {
        self._activeModelName = activeModelName
        self.isConnectedToLiveAntigravity = isConnectedToLiveAntigravity
        self.onSelectModel = onSelectModel
        self.onClose = onClose
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("👑")
                    .font(.system(size: 14))
                Text("Sovereign Model Selection")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(ChippyTheme.textPrimary)

                Spacer()

                HStack(spacing: 5) {
                    Circle()
                        .fill(isConnectedToLiveAntigravity ? Color.green : ChippyTheme.statusDot)
                        .frame(width: 6, height: 6)
                    Text(isConnectedToLiveAntigravity ? "Antigravity Live" : "Replay Stream")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(ChippyTheme.textMuted)
                }
            }

            Text("The Sovereign commands the colony. Models are dynamically detected from active Antigravity sessions.")
                .font(.system(size: 11))
                .foregroundColor(ChippyTheme.textMuted)

            Divider()
                .background(ChippyTheme.borderSubtle)

            // Model List
            VStack(spacing: 6) {
                ForEach(availableModels, id: \.self) { model in
                    let isCurrent = activeModelName == model || (activeModelName.contains("Gemini") && model.contains("Gemini"))
                    Button(action: {
                        onSelectModel(model)
                    }) {
                        HStack {
                            Text(model)
                                .font(.system(size: 12, weight: isCurrent ? .semibold : .regular))
                                .foregroundColor(isCurrent ? ChippyTheme.textPrimary : ChippyTheme.textMuted)

                            Spacer()

                            if isCurrent {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(ChippyTheme.accentSolid)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(isCurrent ? ChippyTheme.surfaceBubble : Color.clear)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(isCurrent ? ChippyTheme.borderSubtle : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .frame(width: 320)
        .background(ChippyTheme.surfacePrimary)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(ChippyTheme.borderSubtle, lineWidth: 1)
        )
    }
}
