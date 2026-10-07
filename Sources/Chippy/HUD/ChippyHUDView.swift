import SwiftUI
import ChippyCore

/// The overlay HUD providing telemetry inspection, Sovereign state indicators,
/// playback controls, interactive skill codex, zoom controls, session picker,
/// teaching mode subtitles, chronicle reviews, and prompt chatbox.
public struct ChippyHUDView: View {
    @Bindable public var appState: AppState

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
    public var onSelectSession: (SessionInfo) -> Void
    public var onRescanSkills: () -> Void

    @State private var showActivityLog: Bool = true
    @State private var showSkillCodex: Bool = false
    @State private var showModelSelector: Bool = false
    @State private var showResponseView: Bool = false
    @State private var promptText: String = ""

    private let narrator = Narrator()

    public init(
        appState: AppState,
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
        onToggleLiveMode: @escaping () -> Void,
        onSelectSession: @escaping (SessionInfo) -> Void,
        onRescanSkills: @escaping () -> Void
    ) {
        self.appState = appState
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
        self.onSelectSession = onSelectSession
        self.onRescanSkills = onRescanSkills
    }

    public var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // TOP BAR
                topBarView
                    .padding(.horizontal, 16)
                    .padding(.top, 14)

                Spacer()

                // TEACHING MODE NARRATION SUBTITLE (if enabled)
                if appState.showTeachingMode, let latest = appState.eventLog.last {
                    narrationSubtitleView(event: latest)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // FLOATING PROMPT CHATBOX (Center Bottom)
                PromptChatboxView(
                    promptText: $promptText,
                    isLiveMode: appState.isLiveAntigravityMode,
                    onToggleLiveMode: onToggleLiveMode,
                    onSubmitPrompt: { prompt in
                        appState.promptSubmittedFromChippy = true
                        onSubmitPrompt(prompt)
                    }
                )
                .frame(maxWidth: 620)
                .padding(.bottom, 12)

                // BOTTOM BAR & LOG DRAWER
                HStack(alignment: .bottom, spacing: 14) {
                    if showActivityLog {
                        ActivityLogView(events: appState.eventLog)
                            .frame(width: 380, height: 210)
                            .transition(.move(edge: .leading).combined(with: .opacity))
                    }

                    Spacer()

                    bottomControlsView
                }
                .padding(16)
            }

            // FLOATING COUNCIL RESPONSE INSPECTOR
            if showResponseView, let response = appState.latestResponse, !response.isEmpty {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.15)) {
                            showResponseView = false
                            appState.hasUnreadResponse = false
                        }
                    }

                AgentResponseView(
                    responseText: response,
                    modelName: appState.activeModelName,
                    onClose: {
                        withAnimation(.easeOut(duration: 0.15)) {
                            showResponseView = false
                            appState.hasUnreadResponse = false
                        }
                    }
                )
                .transition(.scale(scale: 0.95).combined(with: .opacity))
                .zIndex(50)
            }

            // CHRONICLE REPORT MODAL
            if appState.showChronicle {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.15)) { appState.showChronicle = false }
                    }

                ChronicleView(
                    chronicle: SessionChronicle(events: appState.eventLog),
                    sessionTitle: appState.activeSessionID ?? "Antigravity Session",
                    onClose: {
                        withAnimation(.easeOut(duration: 0.15)) { appState.showChronicle = false }
                    }
                )
                .transition(.scale(scale: 0.95).combined(with: .opacity))
                .zIndex(55)
            }
        }
        .onChange(of: appState.latestResponse) { _, newResponse in
            if let newResponse, !newResponse.isEmpty {
                if appState.promptSubmittedFromChippy {
                    // Auto-open response modal only for prompts initiated within Chippy
                    appState.promptSubmittedFromChippy = false
                    appState.hasUnreadResponse = false
                    withAnimation(.easeOut(duration: 0.2)) {
                        showResponseView = true
                    }
                } else {
                    // For passive background session tailing, show discrete unread dot on Dispatch
                    appState.hasUnreadResponse = true
                }
            }
        }
        .sheet(isPresented: $showSkillCodex) {
            SkillCodexView(
                skills: appState.loadedSkills,
                onSelectSkill: { skill in
                    onSelectSkill(skill)
                    showSkillCodex = false
                },
                onClose: { showSkillCodex = false }
            )
        }
        .sheet(isPresented: $appState.showSettings) {
            SettingsView(appState: appState, onRescanSkills: onRescanSkills)
        }
    }

    // MARK: - Subviews

    private var topBarView: some View {
        HStack(spacing: 10) {
            // Observed Model Indicator
            Button(action: { showModelSelector.toggle() }) {
                HStack(spacing: 8) {
                    Text("👑")
                        .font(.system(size: 14))

                    VStack(alignment: .leading, spacing: 1) {
                        Text("OBSERVED MODEL")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(ChippyTheme.textMuted)

                        Text(appState.activeModelName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(ChippyTheme.textPrimary)
                    }

                    Circle()
                        .fill(ChippyTheme.statusDot)
                        .opacity(appState.isLiveAntigravityMode ? 1.0 : 0.45)
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
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(ChippyTheme.borderSubtle, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showModelSelector) {
                ModelSelectorView(
                    activeModelName: $appState.activeModelName,
                    isConnectedToLiveAntigravity: appState.isLiveAntigravityMode,
                    onSelectModel: { model in
                        onSelectModel(model)
                        showModelSelector = false
                    },
                    onClose: { showModelSelector = false }
                )
            }

            // Session Picker Menu (Sprint D3)
            if !appState.availableSessions.isEmpty {
                Menu {
                    Text("Active & Recent Sessions").font(.caption)
                    Divider()
                    ForEach(appState.availableSessions) { session in
                        Button(action: { onSelectSession(session) }) {
                            HStack {
                                if session.isActive {
                                    Text("● Active: \(session.displayName)")
                                } else {
                                    Text(session.displayName)
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 11))
                            .foregroundColor(ChippyTheme.textMuted)
                        Text(currentSessionLabel)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(ChippyTheme.textPrimary)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(ChippyTheme.textMuted)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(ChippyTheme.surfaceBubble)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(ChippyTheme.borderSubtle, lineWidth: 1))
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }

            Spacer()

            // Replay Controls (in Replay Mode)
            if !appState.isLiveAntigravityMode {
                replayControlsView
            } else {
                liveIndicatorView
            }

            // Pin on Top Toggle (Sprint A6)
            Button(action: { appState.isPinnedOnTop.toggle() }) {
                Image(systemName: appState.isPinnedOnTop ? "pin.fill" : "pin")
                    .font(.system(size: 11))
                    .foregroundColor(appState.isPinnedOnTop ? ChippyTheme.textPrimary : ChippyTheme.textMuted)
                    .padding(8)
                    .background(ChippyTheme.surfaceBubble)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(ChippyTheme.borderSubtle, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .help(appState.isPinnedOnTop ? "Unpin Window" : "Pin Window on Top (HUD Mode)")

            // Settings Button (Sprint B2)
            Button(action: { appState.showSettings = true }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 11))
                    .foregroundColor(ChippyTheme.textPrimary)
                    .padding(8)
                    .background(ChippyTheme.surfaceBubble)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(ChippyTheme.borderSubtle, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .help("Preferences & Skill Sources")
        }
    }

    private var currentSessionLabel: String {
        if let current = appState.activeSessionID {
            return String(current.prefix(8))
        }
        return "Sessions"
    }

    private var liveIndicatorView: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(ChippyTheme.statusDot)
                .frame(width: 6, height: 6)
            Text("Streaming Live Antigravity")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(ChippyTheme.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(ChippyTheme.surfaceBubble)
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(ChippyTheme.borderSubtle, lineWidth: 1))
    }

    private var replayControlsView: some View {
        HStack(spacing: 10) {
            Button(action: onStepBackward) {
                Image(systemName: "backward.frame.fill")
                    .font(.system(size: 11))
                    .foregroundColor(ChippyTheme.textPrimary)
            }
            .buttonStyle(.plain)

            Button(action: onPlayPause) {
                Image(systemName: appState.isPlaying ? "pause.fill" : "play.fill")
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

            Menu {
                ForEach(PlaybackSpeed.allCases, id: \.self) { speed in
                    Button(speed.displayLabel) { onSpeedChange(speed) }
                }
            } label: {
                Text(appState.currentSpeed.displayLabel)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(ChippyTheme.textPrimary)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()

            Text("(\(appState.currentProgress)/\(appState.totalEvents))")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(ChippyTheme.textMuted)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(ChippyTheme.surfaceBubble)
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(ChippyTheme.borderSubtle, lineWidth: 1))
    }

    private func narrationSubtitleView(event: AgentEvent) -> some View {
        HStack(spacing: 8) {
            Text("💡")
                .font(.system(size: 11))
            Text(narrator.narrate(event: event))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(ChippyTheme.textPrimary)
                .lineLimit(1)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(ChippyTheme.surfaceBubble.opacity(0.9))
        .cornerRadius(6)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(ChippyTheme.borderSubtle, lineWidth: 0.5))
        .frame(maxWidth: 620)
    }

    private var bottomControlsView: some View {
        HStack(spacing: 8) {
            // Chronicle Report Button (Sprint E2)
            Button(action: { withAnimation { appState.showChronicle = true } }) {
                HStack(spacing: 5) {
                    Image(systemName: "scroll")
                        .font(.system(size: 11))
                    Text("Chronicle")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(ChippyTheme.textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(ChippyTheme.surfaceBubble)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(ChippyTheme.borderSubtle, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .help("View Session Summary Chronicle")

            // Skills Codex Button
            Button(action: { showSkillCodex = true }) {
                HStack(spacing: 6) {
                    Text("🛠️")
                        .font(.system(size: 12))
                    Text("\(appState.loadedSkills.count) Skills")
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
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(ChippyTheme.borderSubtle, lineWidth: 1))
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
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(ChippyTheme.borderSubtle, lineWidth: 1))
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
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(ChippyTheme.borderSubtle, lineWidth: 1))
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
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(ChippyTheme.borderSubtle, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .help("Recenter Camera (Space / R / Double-Click)")

            // Council Dispatch Button
            if let response = appState.latestResponse, !response.isEmpty {
                Button(action: {
                    appState.hasUnreadResponse = false
                    withAnimation(.easeOut(duration: 0.15)) { showResponseView.toggle() }
                }) {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(ChippyTheme.statusDot)
                            .frame(width: 5, height: 5)
                            .opacity(appState.hasUnreadResponse ? 1.0 : 0.4)
                        Text("Dispatch")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(ChippyTheme.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(ChippyTheme.surfaceBubble)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(ChippyTheme.borderSubtle, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .help("Open Full Council Dispatch Response")
            }

            // Toggle Log Drawer
            Button(action: { withAnimation { showActivityLog.toggle() } }) {
                Image(systemName: showActivityLog ? "sidebar.left" : "sidebar.leading")
                    .font(.system(size: 12))
                    .foregroundColor(ChippyTheme.textPrimary)
                    .padding(8)
                    .background(ChippyTheme.surfaceBubble)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(ChippyTheme.borderSubtle, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .help("Toggle Activity Log")
        }
    }
}
