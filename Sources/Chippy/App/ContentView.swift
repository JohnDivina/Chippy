import SwiftUI
import SpriteKit
import ChippyCore

/// Root view assembling the 2.5D SpriteKit diorama canvas and SwiftUI HUD overlay.
public struct ContentView: View {
    @State private var scene: ParadiseScene
    @State private var director: SceneDirector
    @State private var replayEngine: ReplayEngine?
    @State private var telemetryWatcher: TelemetryWatcher?

    @State private var activeModelName: String = "Observing Model..."
    @State private var isPlaying: Bool = false
    @State private var currentSpeed: PlaybackSpeed = .normal
    @State private var currentProgress: Int = 0
    @State private var totalEvents: Int = 0
    @State private var loadedSkills: [SkillWorkshop] = []
    @State private var eventLog: [AgentEvent] = []
    @State private var isLiveAntigravityMode: Bool = true
    @State private var dragAccumulator: CGSize = .zero

    public init() {
        let newScene = ParadiseScene(size: CGSize(width: 1024, height: 768))
        let newDirector = SceneDirector(scene: newScene)
        _scene = State(initialValue: newScene)
        _director = State(initialValue: newDirector)
    }

    public var body: some View {
        ZStack {
            // 2.5D SpriteKit Diorama View
            GeometryReader { geo in
                SpriteView(
                    scene: scene,
                    preferredFramesPerSecond: 60,
                    options: [.shouldCullNonVisibleNodes]
                )
                .frame(width: geo.size.width, height: geo.size.height)
                .onAppear {
                    if geo.size.width > 0 && geo.size.height > 0 {
                        scene.size = geo.size
                    }
                }
                .onChange(of: geo.size) { _, newSize in
                    if newSize.width > 0 && newSize.height > 0 {
                        scene.size = newSize
                    }
                }
            }
            .ignoresSafeArea()
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        let deltaX = value.translation.width - dragAccumulator.width
                        let deltaY = value.translation.height - dragAccumulator.height
                        dragAccumulator = value.translation
                        scene.panCamera(by: CGPoint(
                            x: deltaX * scene.cameraNode.xScale,
                            y: -deltaY * scene.cameraNode.yScale
                        ))
                    }
                    .onEnded { _ in
                        dragAccumulator = .zero
                    }
            )

            // Hidden shortcut button for quick camera reset (R)
            Button("") { scene.resetCamera() }
                .keyboardShortcut("r", modifiers: [])
                .opacity(0)
                .frame(width: 0, height: 0)

            // Anti-slop SwiftUI HUD
            ChippyHUDView(
                activeModelName: $activeModelName,
                isPlaying: $isPlaying,
                currentSpeed: $currentSpeed,
                currentProgress: $currentProgress,
                isLiveAntigravityMode: $isLiveAntigravityMode,
                totalEvents: totalEvents,
                skills: loadedSkills,
                events: eventLog,
                onPlayPause: togglePlayPause,
                onStepForward: stepForward,
                onStepBackward: stepBackward,
                onSpeedChange: changeSpeed,
                onResetCamera: { scene.resetCamera() },
                onZoomIn: { scene.zoomIn() },
                onZoomOut: { scene.zoomOut() },
                onSelectSkill: handleSelectSkill,
                onSelectModel: handleSelectModel,
                onSubmitPrompt: handlePromptSubmit,
                onToggleLiveMode: toggleLiveMode
            )
        }
        .frame(minWidth: 960, minHeight: 640)
        .task {
            await initializeChippy()
        }
    }

    // MARK: - Lifecycle & Actions

    @MainActor
    private func initializeChippy() async {
        // 1. Ingest all 48 production skills directly from workspace
        let productionSkillsURL = URL(fileURLWithPath: "/Users/johnrey/Desktop/Programming/production-agents/.agents/skills")
        let discovery = SkillDiscovery()
        let discovered = discovery.discoverSkills(
            userCustomFolders: [productionSkillsURL],
            workspaceURL: URL(fileURLWithPath: "/Users/johnrey/Desktop/Programming")
        )
        self.loadedSkills = discovered

        // 2. Setup Live Antigravity Telemetry Watcher
        let watcher = TelemetryWatcher()
        self.telemetryWatcher = watcher

        if isLiveAntigravityMode {
            startLiveWatching(watcher: watcher)
        } else {
            setupReplayFixture()
        }
    }

    private func startLiveWatching(watcher: TelemetryWatcher) {
        if let latestURL = SessionLocator().findLatestTranscriptURL() {
            Task {
                let stream = await watcher.startWatching(fileURL: latestURL, readFromBeginning: true)
                for await event in stream {
                    await MainActor.run {
                        director.handleEvent(event)
                        eventLog.append(event)
                        activeModelName = director.activeModelName
                    }
                }
            }
        } else {
            // Fallback to bundled fixture if no local Antigravity session found
            setupReplayFixture()
        }
    }

    private func setupReplayFixture() {
        let adapter = AntigravityAdapter()
        if let fixtureURL = ReplayEngine.defaultRecordingURL(),
           let engine = try? ReplayEngine(transcriptURL: fixtureURL, adapter: adapter) {
            self.replayEngine = engine
            Task {
                let count = await engine.totalEvents
                await MainActor.run { self.totalEvents = count }
            }
        }
    }

    private func toggleLiveMode() {
        isLiveAntigravityMode.toggle()
        eventLog.removeAll()

        if isLiveAntigravityMode {
            if let watcher = telemetryWatcher {
                startLiveWatching(watcher: watcher)
            }
        } else {
            Task {
                await telemetryWatcher?.stopWatching()
            }
            setupReplayFixture()
        }
    }

    private func handlePromptSubmit(_ prompt: String) {
        let userEvent = AgentEvent.userPrompt(text: prompt)
        eventLog.append(userEvent)
        director.handleEvent(userEvent)

        // Trigger Sovereign thinking and familiar delegation animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            let thinkEvent = AgentEvent.thinking(agentID: "sovereign")
            eventLog.append(thinkEvent)
            director.handleEvent(thinkEvent)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            let msgEvent = AgentEvent.agentMessage(agentID: "sovereign", text: "Quest logged in diorama! Note: Live coding is driven directly from your active Antigravity session.")
            eventLog.append(msgEvent)
            director.handleEvent(msgEvent)
        }
    }

    private func handleSelectSkill(_ skill: SkillWorkshop) {
        scene.focusLandmark(key: skill.districtID.rawValue)
        let event = AgentEvent.skillLoaded(agentID: "scribe", skillName: skill.name)
        eventLog.append(event)
        director.handleEvent(event)
    }

    private func handleSelectModel(_ model: String) {
        self.activeModelName = model
        let event = AgentEvent.sessionStarted(sessionID: UUID().uuidString, model: model, startedAt: Date())
        eventLog.append(event)
        director.handleEvent(event)
    }

    // MARK: - Replay Controls

    private func togglePlayPause() {
        guard let engine = replayEngine else { return }
        Task {
            let playing = await engine.currentlyPlaying
            if playing {
                await engine.pause()
                await MainActor.run { isPlaying = false }
            } else {
                await engine.play()
                await MainActor.run { isPlaying = true }
                listenToStream(engine: engine)
            }
        }
    }

    private func listenToStream(engine: ReplayEngine) {
        Task {
            let stream = await engine.makeEventStream()
            for await event in stream {
                await MainActor.run {
                    director.handleEvent(event)
                    eventLog.append(event)
                    activeModelName = director.activeModelName
                }
                let progress = await engine.currentProgress
                await MainActor.run {
                    currentProgress = progress
                }
            }
            await MainActor.run { isPlaying = false }
        }
    }

    private func stepForward() {
        guard let engine = replayEngine else { return }
        Task {
            if let event = await engine.stepForward() {
                await MainActor.run {
                    director.handleEvent(event)
                    eventLog.append(event)
                    activeModelName = director.activeModelName
                }
                let progress = await engine.currentProgress
                await MainActor.run { currentProgress = progress }
            }
        }
    }

    private func stepBackward() {
        guard let engine = replayEngine else { return }
        Task {
            if let event = await engine.stepBackward() {
                await MainActor.run {
                    director.handleEvent(event)
                }
                let progress = await engine.currentProgress
                await MainActor.run { currentProgress = progress }
            }
        }
    }

    private func changeSpeed(_ speed: PlaybackSpeed) {
        currentSpeed = speed
        guard let engine = replayEngine else { return }
        Task {
            await engine.setSpeed(speed)
        }
    }
}
