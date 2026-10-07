import SwiftUI
import AppKit
import ChippyCore

/// Floating full markdown response viewer allowing users to read the complete
/// text from Antigravity and copy code or explanations with zero truncation.
/// Strictly conforms to the workspace anti-slop guidelines: solid dark grey bubbles,
/// crisp borders, high contrast, zero neon/glowing accents.
public struct AgentResponseView: View {
    public let responseText: String
    public let modelName: String
    public var onClose: () -> Void

    @State private var hasCopied: Bool = false

    public init(
        responseText: String,
        modelName: String = "Antigravity Council",
        onClose: @escaping () -> Void
    ) {
        self.responseText = responseText
        self.modelName = modelName
        self.onClose = onClose
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Bar
            HStack(spacing: 8) {
                // Discrete solid status dot
                Circle()
                    .fill(ChippyTheme.statusDot)
                    .frame(width: 6, height: 6)

                Text("Council Dispatch")
                    .font(.system(size: 12, weight: .bold, design: .default))
                    .foregroundColor(ChippyTheme.textPrimary)

                Text(modelName)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(ChippyTheme.textMuted)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(ChippyTheme.surfaceBubble)
                    .cornerRadius(4)

                Spacer()

                // Copy button
                Button(action: copyToClipboard) {
                    HStack(spacing: 4) {
                        Image(systemName: hasCopied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 10))
                        Text(hasCopied ? "Copied" : "Copy")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(ChippyTheme.textPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(ChippyTheme.surfaceBubble)
                    .cornerRadius(5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(ChippyTheme.borderSubtle, lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)

                // Close button
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(ChippyTheme.textMuted)
                        .padding(5)
                        .background(ChippyTheme.surfaceBubble)
                        .cornerRadius(5)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(ChippyTheme.surfacePrimary)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(ChippyTheme.borderSubtle),
                alignment: .bottom
            )

            // Scrollable response body
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    Text(cleanResponse(responseText))
                        .font(.system(size: 12, design: .default))
                        .lineSpacing(4)
                        .foregroundColor(ChippyTheme.textPrimary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(14)
            }
            .background(ChippyTheme.surfaceBubble)
        }
        .frame(width: 480, height: 320)
        .background(ChippyTheme.surfacePrimary)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(ChippyTheme.borderSubtle, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 4)
    }

    private func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(responseText, forType: .string)
        withAnimation {
            hasCopied = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                hasCopied = false
            }
        }
    }

    private func cleanResponse(_ text: String) -> String {
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
