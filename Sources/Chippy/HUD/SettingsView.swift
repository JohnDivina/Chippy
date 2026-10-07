import SwiftUI
import AppKit
import ChippyCore

/// Settings view allowing customization of skill sources, transcript directories,
/// window pinning, notifications, and accessibility options.
/// Strictly conforms to workspace anti-slop guidelines: solid dark grey bubbles, crisp borders.
public struct SettingsView: View {
    @Bindable public var appState: AppState
    public var onRescanSkills: () -> Void

    @AppStorage("brainDirectoryPath") private var brainDirectoryPath: String = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".gemini/antigravity-ide/brain").path
    @AppStorage("autoFollowSessions") private var autoFollowSessions: Bool = true
    @AppStorage("enableNotifications") private var enableNotifications: Bool = true
    @AppStorage("reduceMotion") private var reduceMotion: Bool = false

    @Environment(\.dismiss) private var dismiss

    public init(appState: AppState, onRescanSkills: @escaping () -> Void) {
        self.appState = appState
        self.onRescanSkills = onRescanSkills
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header
            HStack {
                Text("⚙️ Chippy Settings")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(ChippyTheme.textPrimary)
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(ChippyTheme.surfaceBubble)
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(ChippyTheme.borderSubtle, lineWidth: 1))
            }

            Divider().background(ChippyTheme.borderSubtle)

            // Section 1: Behavior & Window
            VStack(alignment: .leading, spacing: 10) {
                Text("Window & Behavior")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(ChippyTheme.textMuted)

                Toggle("Pin Window on Top (Floating HUD)", isOn: $appState.isPinnedOnTop)
                    .toggleStyle(.checkbox)
                    .font(.system(size: 12))
                    .foregroundColor(ChippyTheme.textPrimary)

                Toggle("Automatically follow new Antigravity sessions", isOn: $autoFollowSessions)
                    .toggleStyle(.checkbox)
                    .font(.system(size: 12))
                    .foregroundColor(ChippyTheme.textPrimary)

                Toggle("Enable 'Needs You' system notifications (prompts & errors)", isOn: $enableNotifications)
                    .toggleStyle(.checkbox)
                    .font(.system(size: 12))
                    .foregroundColor(ChippyTheme.textPrimary)

                Toggle("Reduce Motion (gentle fades, no sprite bobbing)", isOn: $reduceMotion)
                    .toggleStyle(.checkbox)
                    .font(.system(size: 12))
                    .foregroundColor(ChippyTheme.textPrimary)

                Toggle("Play spatial audio chimes (decision bell, quest chimes)", isOn: Binding(
                    get: { SoundEffects.shared.isEnabled },
                    set: { SoundEffects.shared.isEnabled = $0 }
                ))
                .toggleStyle(.checkbox)
                .font(.system(size: 12))
                .foregroundColor(ChippyTheme.textPrimary)

                Toggle("Show plain-English Teaching Mode subtitles banner", isOn: $appState.showTeachingMode)
                    .toggleStyle(.checkbox)
                    .font(.system(size: 12))
                    .foregroundColor(ChippyTheme.textPrimary)
            }
            .padding(12)
            .background(ChippyTheme.surfaceBubble)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(ChippyTheme.borderSubtle, lineWidth: 0.5))

            // Section 2: Transcript Directory
            VStack(alignment: .leading, spacing: 8) {
                Text("Antigravity Brain Directory")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(ChippyTheme.textMuted)

                HStack {
                    TextField("Brain storage path", text: $brainDirectoryPath)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11, design: .monospaced))
                        .padding(7)
                        .background(ChippyTheme.surfacePrimary)
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(ChippyTheme.borderSubtle, lineWidth: 1))

                    Button("Reset") {
                        brainDirectoryPath = FileManager.default.homeDirectoryForCurrentUser
                            .appendingPathComponent(".gemini/antigravity-ide/brain").path
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(ChippyTheme.surfacePrimary)
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(ChippyTheme.borderSubtle, lineWidth: 1))
                }
            }
            .padding(12)
            .background(ChippyTheme.surfaceBubble)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(ChippyTheme.borderSubtle, lineWidth: 0.5))

            // Section 3: Skill Sources
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Production Skills Codex (\(appState.loadedSkills.count) loaded)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(ChippyTheme.textMuted)
                    Spacer()
                    Button("Rescan Skills") {
                        onRescanSkills()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(ChippyTheme.surfacePrimary)
                    .cornerRadius(5)
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(ChippyTheme.borderSubtle, lineWidth: 0.5))
                }

                Text("Skills are auto-discovered from `.agents/skills`, `~/.gemini/config/skills`, and active workspaces.")
                    .font(.system(size: 10))
                    .foregroundColor(ChippyTheme.textMuted)
            }
            .padding(12)
            .background(ChippyTheme.surfaceBubble)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(ChippyTheme.borderSubtle, lineWidth: 0.5))

            Spacer()
        }
        .padding(20)
        .frame(width: 480, height: 440)
        .background(ChippyTheme.surfacePrimary)
    }
}
