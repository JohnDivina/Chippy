import SwiftUI
import ChippyCore

/// The overlay HUD providing telemetry inspection, Sovereign state indicators,
/// playback controls, and skill district summaries.
public struct ChippyHUDView: View {
    @Binding public var activeModelName: String
    @Binding public var isPlaying: Bool
    @Binding public var currentSpeed: PlaybackSpeed
    @Binding public var currentProgress: Int
    public let totalEvents: Int
    public let loadedSkillCount: Int
    public let events: [AgentEvent]

    public var onPlayPause: () -> Void
    public var onStepForward: () -> Void
    public var onStepBackward: () -> Void
    public var onSpeedChange: (PlaybackSpeed) -> Void
    public var onResetCamera: () -> Void

    @State private var showActivityLog: Bool = true

    public init(
        activeModelName: Binding<String>,
        isPlaying: Binding<Bool>,
        currentSpeed: Binding<PlaybackSpeed>,
        currentProgress: Binding<Int>,
        totalEvents: Int,
        loadedSkillCount: Int,
        events: [AgentEvent],
        onPlayPause: @escaping () -> Void,
        onStepForward: @escaping () -> Void,
        onStepBackward: @escaping () -> Void,
        onSpeedChange: @escaping (PlaybackSpeed) -> Void,
        onResetCamera: @escaping () -> Void
    ) {
        self._activeModelName = activeModelName
        self._isPlaying = isPlaying
        self._currentSpeed = currentSpeed
        self._currentProgress = currentProgress
        self.totalEvents = totalEvents
        self.loadedSkillCount = loadedSkillCount
        self.events = events
        self.onPlayPause = onPlayPause
        self.onStepForward = onStepForward
        self.onStepBackward = onStepBackward
        self.onSpeedChange = onSpeedChange
        self.onResetCamera = onResetCamera
    }

    public var body: some View {
        VStack(spacing: 0) {
            // TOP BAR
            topBarView
                .padding(.horizontal, 16)
                .padding(.top, 14)

            Spacer()

            // BOTTOM BAR & LOG DRAWER
            HStack(alignment: .bottom, spacing: 14) {
                if showActivityLog {
                    ActivityLogView(events: events)
                        .frame(width: 380, height: 220)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                }

                Spacer()

                bottomControlsView
            }
            .padding(16)
        }
    }

    // MARK: - Subviews

    private var topBarView: some View {
        HStack(spacing: 12) {
            // Sovereign Model Indicator (Anti-slop solid bubble)
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
                    .fill(ChippyTheme.statusDot)
                    .frame(width: 6, height: 6)
                    .padding(.leading, 4)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(ChippyTheme.surfaceBubble)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(ChippyTheme.borderSubtle, lineWidth: 1)
            )

            Spacer()

            // Replay Playback Controls
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
        }
    }

    private var bottomControlsView: some View {
        HStack(spacing: 10) {
            // Skills count bubble
            HStack(spacing: 6) {
                Text("🛠️")
                    .font(.system(size: 11))
                Text("\(loadedSkillCount) Production Skills")
                    .font(.system(size: 11, weight: .medium))
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

            // Camera Center Button
            Button(action: onResetCamera) {
                Image(systemName: "scope")
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
        }
    }
}
