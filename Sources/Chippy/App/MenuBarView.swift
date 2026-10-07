import SwiftUI
import AppKit
import ChippyCore

/// Compact menu bar status view providing a glanceable glance at current Sovereign activity.
public struct MenuBarView: View {
    @Bindable public var appState: AppState
    public var onOpenMainWindow: () -> Void

    public init(appState: AppState, onOpenMainWindow: @escaping () -> Void) {
        self.appState = appState
        self.onOpenMainWindow = onOpenMainWindow
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(spacing: 8) {
                Text("👑")
                    .font(.system(size: 14))
                VStack(alignment: .leading, spacing: 2) {
                    Text("THE SOVEREIGN")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(ChippyTheme.textMuted)
                    Text(appState.activeModelName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(ChippyTheme.textPrimary)
                }
                Spacer()
                Circle()
                    .fill(ChippyTheme.statusDot)
                    .frame(width: 6, height: 6)
            }

            Divider().background(ChippyTheme.borderSubtle)

            // Current Activity
            VStack(alignment: .leading, spacing: 4) {
                Text("CURRENT STATUS")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(ChippyTheme.textMuted)

                Text(statusText)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(ChippyTheme.textPrimary)
                    .lineLimit(2)
            }

            Divider().background(ChippyTheme.borderSubtle)

            // Quick actions
            HStack {
                Button("Open Island Diorama") {
                    onOpenMainWindow()
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(ChippyTheme.surfaceBubble)
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(ChippyTheme.borderSubtle, lineWidth: 1))

                Spacer()

                Button("Quit") {
                    NSApp.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundColor(ChippyTheme.textMuted)
            }
        }
        .padding(12)
        .frame(width: 260)
        .background(ChippyTheme.surfacePrimary)
    }

    private var statusText: String {
        if let last = appState.eventLog.last {
            return Narrator().narrate(event: last)
        }
        return appState.isLiveAntigravityMode ? "Observing live Antigravity sessions..." : "Idle in replay mode."
    }
}
