import SwiftUI
import ChippyCore

/// The overlay HUD providing telemetry inspection, Sovereign state indicators,
/// playback controls, interactive skill codex, zoom controls, and prompt chatbox.
public struct ChippyHUDView: View {
    @Binding public var activeModelName: String
    @Binding public var isPlaying: Bool
    @Binding public var currentSpeed: PlaybackSpeed
    @Binding public var currentProgress: Int
    @Binding public var isLiveAntigravityMode: Bool

    public let totalEvents: Int
    public let skills: [SkillWorkshop]
    public let events: [AgentEvent]

    public var onPlayPause: () -> Void
    public var onStepForward: () -> Void
    public var onStepBackward: () -> Void
    public var onSpeedChange: (PlaybackSpeed) -> Void
    public var onResetCamera: () -> Void
    public var onZoomIn: () -> Void
    public var onZoomOut: () -> Void
    public var onSelectSkill: (SkillWorkshop) -> Void
    public var onSelectModel: (String) -> Void
    public var onSubmitPrompt: (String) -> Void
    public var onToggleLiveMode: () -> Void

    @State private var showActivityLog: Bool = true
    @State private var showSkillCodex: Bool = false
    @State private var showModelSelector: Bool = false
    @State private var promptText: String = ""

    public init(
        activeModelName: Binding<String>,
        isPlaying: Binding<Bool>,
        currentSpeed: Binding<PlaybackSpeed>,
        currentProgress: Binding<Int>,
        isLiveAntigravityMode: Binding<Bool>,
        totalEvents: Int,
        skills: [SkillWorkshop],
        events: [AgentEvent],
        onPlayPause: @escaping () -> Void,
        onStepForward: @escaping () -> Void,
        onStepBackward: @escaping () -> Void,
        onSpeedChange: @escaping (PlaybackSpeed) -> Void,
        onResetCamera: @escaping () -> Void,
        onZoomIn: @escaping () -> Void,
        onZoomOut: @escaping () -> Void,
        onSelectSkill: @escaping (SkillWorkshop) -> Void,
        onSelectModel: @escaping (String) -> Void,
        onSubmitPrompt: @escaping (String) -> Void,
        onToggleLiveMode: @escaping () -> Void
    ) {
        self._activeModelName = activeModelName
        self._isPlaying = isPlaying
        self._currentSpeed = currentSpeed
        self._currentProgress = currentProgress
        self._isLiveAntigravityMode = isLiveAntigravityMode
        self.totalEvents = totalEvents
        self.skills = skills
        self.events = events
        self.onPlayPause = onPlayPause
        self.onStepForward = onStepForward
        self.onStepBackward = onStepBackward
        self.onSpeedChange = onSpeedChange
        self.onResetCamera = onResetCamera
        self.onZoomIn = onZoomIn
        self.onZoomOut = onZoomOut
        self.onSelectSkill = onSelectSkill
        self.onSelectModel = onSelectModel
        self.onSubmitPrompt = onSubmitPrompt
        self.onToggleLiveMode = onToggleLiveMode
    }

    public var body: some View {
        VStack(spacing: 0) {
            // TOP BAR
            topBarView
                .padding(.horizontal, 16)
                .padding(.top, 14)

            Spacer()

            // FLOATING PROMPT CHATBOX (Center Bottom)
            PromptChatboxView(
                promptText: $promptText,
                isLiveMode: isLiveAntigravityMode,
                onToggleLiveMode: onToggleLiveMode,
                onSubmitPrompt: onSubmitPrompt
            )
            .frame(maxWidth: 620)
            .padding(.bottom, 12)

            // BOTTOM BAR & LOG DRAWER
            HStack(alignment: .bottom, spacing: 14) {
                if showActivityLog {
                    ActivityLogView(events: events)
                        .frame(width: 380, height: 210)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }

                Spacer()

                bottomControlsView
            }
            .padding(16)
        }
        .sheet(isPresented: $showSkillCodex) {
            SkillCodexView(
                skills: skills,
                onSelectSkill: { skill in
                    onSelectSkill(skill)
                    showSkillCodex = false
                },
                onClose: { showSkillCodex = false }
            )
        }
    }

    // MARK: - Subviews

    private var topBarView: some View {
        HStack(spacing: 12) {
            // Clickable Sovereign Model Indicator
            Button(action: { showModelSelector.toggle() }) {
                HStack(spacing: 8) {
                    Text("👑")
                        .font(.system(size: 14))

                    VStack(alignment: .leading, spacing: 1) {
                        Text("THE SOVEREIGN")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(ChippyTheme.textMuted)

                        Text(activeModelName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(ChippyTheme.textPrimary)
                    }

                    Circle()
                        .fill(isLiveAntigravityMode ? Color.green : ChippyTheme.statusDot)
                        .frame(width: 6, height: 6)
                        .padding(.leading, 4)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(ChippyTheme.textMuted)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(ChippyTheme.surfaceBubble)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(ChippyTheme.borderSubtle, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showModelSelector) {
                ModelSelectorView(
                    activeModelName: $activeModelName,
                    isConnectedToLiveAntigravity: isLiveAntigravityMode,
                    onSelectModel: { model in
                        onSelectModel(model)
                        showModelSelector = false
                    },
                    onClose: { showModelSelector = false }
                )
            }

            Spacer()

            // Replay Playback Controls (Active in Replay mode)
            if !isLiveAntigravityMode {
                HStack(spacing: 10) {
                    Button(action: onStepBackward) {
                        Image(systemName: "backward.frame.fill")
                            .font(.system(size: 11))
                            .foregroundColor(ChippyTheme.textPrimary)
                    }
                    .buttonStyle(.plain)

                    Button(action: onPlayPause) {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(ChippyTheme.textPrimary)
                    }
                    .buttonStyle(.plain)

                    Button(action: onStepForward) {
                        Image(systemName: "forward.frame.fill")
                            .font(.system(size: 11))
                            .foregroundColor(ChippyTheme.textPrimary)
                    }
                    .buttonStyle(.plain)

                    Divider()
                        .frame(height: 14)
                        .background(ChippyTheme.borderSubtle)

                    // Speed Selector
                    Menu {
                        ForEach(PlaybackSpeed.allCases, id: \.self) { speed in
                            Button(speed.displayLabel) {
                                onSpeedChange(speed)
                            }
                        }
                    } label: {
                        Text(currentSpeed.displayLabel)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(ChippyTheme.textPrimary)
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()

                    Text("(\(currentProgress)/\(totalEvents))")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(ChippyTheme.textMuted)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(ChippyTheme.surfaceBubble)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(ChippyTheme.borderSubtle, lineWidth: 1)
                )
            } else {
                // Live Stream Indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    Text("Streaming Live Antigravity Activity")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(ChippyTheme.textPrimary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(ChippyTheme.surfaceBubble)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(ChippyTheme.borderSubtle, lineWidth: 1)
                )
            }
        }
    }

    private var bottomControlsView: some View {
        HStack(spacing: 8) {
            // Clickable Skills Codex Button
            Button(action: { showSkillCodex = true }) {
                HStack(spacing: 6) {
                    Text("🛠️")
                        .font(.system(size: 12))
                    Text("\(skills.count) Production Skills")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(ChippyTheme.textPrimary)
                    Image(systemName: "chevron.up")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(ChippyTheme.textMuted)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(ChippyTheme.surfaceBubble)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(ChippyTheme.borderSubtle, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            // Zoom Out Button (-)
            Button(action: onZoomOut) {
                Image(systemName: "minus.magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundColor(ChippyTheme.textPrimary)
                    .padding(8)
                    .background(ChippyTheme.surfaceBubble)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(ChippyTheme.borderSubtle, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .help("Zoom Out")

            // Zoom In Button (+)
            Button(action: onZoomIn) {
                Image(systemName: "plus.magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundColor(ChippyTheme.textPrimary)
                    .padding(8)
                    .background(ChippyTheme.surfaceBubble)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(ChippyTheme.borderSubtle, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .help("Zoom In")

            // Camera Center Button
            Button(action: onResetCamera) {
                HStack(spacing: 5) {
                    Image(systemName: "scope")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Center Island")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(ChippyTheme.textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(ChippyTheme.surfaceBubble)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(ChippyTheme.borderSubtle, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .help("Recenter Camera on Sanctuary Island (Space / R / Double-Click)")

            // Toggle Log Drawer
            Button(action: { withAnimation { showActivityLog.toggle() } }) {
                Image(systemName: showActivityLog ? "sidebar.left" : "sidebar.leading")
                    .font(.system(size: 12))
                    .foregroundColor(ChippyTheme.textPrimary)
                    .padding(8)
                    .background(ChippyTheme.surfaceBubble)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(ChippyTheme.borderSubtle, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .help("Toggle Activity Log")
        }
    }
}
