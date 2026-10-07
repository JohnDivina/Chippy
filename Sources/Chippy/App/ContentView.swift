import SwiftUI
import SpriteKit
import ChippyCore

/// Root view assembling the 2.5D SpriteKit diorama canvas, RenderGovernor, and ChippyHUDView.
public struct ContentView: View {
    @Bindable public var appState: AppState

    @State private var scene: ParadiseScene
    @State private var director: SceneDirector
    @State private var governor: RenderGovernor
    @State private var replayEngine: ReplayEngine?
    @State private var telemetryWatcher: TelemetryWatcher?
    @State private var sessionMonitor: SessionMonitor
    @State private var watchingTask: Task<Void, Never>?
    @State private var sessionMonitorTask: Task<Void, Never>?

    public init(appState: AppState = AppState()) {
        self.appState = appState
        let newScene = ParadiseScene(size: CGSize(width: 1024, height: 768))
        let newDirector = SceneDirector(scene: newScene)
        let newGovernor = RenderGovernor()
        let newMonitor = SessionMonitor()

        _scene = State(initialValue: newScene)
        _director = State(initialValue: newDirector)
        _governor = State(initialValue: newGovernor)
        _sessionMonitor = State(initialValue: newMonitor)
    }

    public var body: some View {
        ZStack {
            // 2.5D SpriteKit Diorama View controlled by RenderGovernor
            GeometryReader { geo in
                ParadiseSKView(scene: scene, governor: governor)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .onAppear {
                        if geo.size.width > 0 && geo.size.height > 0 && scene.size != geo.size {
                            scene.size = geo.size
                        }
                    }
                    .onChange(of: geo.size) { _, newSize in
                        if newSize.width > 0 && newSize.height > 0 && scene.size != newSize {
                            scene.size = newSize
                        }
                    }
            }
            .ignoresSafeArea()

            // Hidden shortcut button for quick camera reset (R)
            Button("") { scene.resetCamera() }
                .keyboardShortcut("r", modifiers: [])
                .opacity(0)
                .frame(width: 0, height: 0)

            // Anti-slop SwiftUI HUD
            ChippyHUDView(
                appState: appState,
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
                onToggleLiveMode: toggleLiveMode,
                onSelectSession: handleSelectSession,
                onRescanSkills: rescanSkills
            )
        }
        .frame(minWidth: 960, minHeight: 640)
        .task {
            NotificationService.shared.requestAuthorizationIfNeeded()
            await initializeChippy()
        }
        .onChange(of: appState.isPinnedOnTop) { _, isPinned in
            updateWindowPinLevel(isPinned: isPinned)
        }
    }

    // MARK: - Initialization & Session Monitoring

    @MainActor
    private func initializeChippy() async {
        // 1. Discover skills without personal hardcoded paths
        rescanSkills()

        // 2. Initialize Telemetry Watcher
        let watcher = TelemetryWatcher()
        self.telemetryWatcher = watcher

        if appState.isLiveAntigravityMode {
            startSessionMonitoringAndLiveWatch(watcher: watcher)
        } else {
            setupReplayFixture()
        }
    }

    @MainActor
    private func rescanSkills() {
        let fileManager = FileManager.default
        let currentDir = URL(fileURLWithPath: fileManager.currentDirectoryPath)

        // Read configured brain/custom paths from UserDefaults
        var customFolders: [URL] = []
        if let customPath = UserDefaults.standard.string(forKey: "customSkillsDirectoryPath"), !customPath.isEmpty {
            customFolders.append(URL(fileURLWithPath: customPath))
        }

        let discovery = SkillDiscovery()
        let discovered = discovery.discoverSkills(
            userCustomFolders: customFolders,
            workspaceURL: currentDir
        )
        appState.loadedSkills = discovered
        director.setKnownSkills(discovered)
    }

    @MainActor
    private func startSessionMonitoringAndLiveWatch(watcher: TelemetryWatcher) {
        sessionMonitorTask?.cancel()

        sessionMonitorTask = Task {
            let stream = await sessionMonitor.startMonitoring(pollIntervalSeconds: 2.0)
            for await sessions in stream {
                await MainActor.run {
                    appState.availableSessions = sessions
                    // Auto-follow: if current active session changed or initial load
                    if let newest = sessions.first {
                        if appState.activeSessionID == nil || (UserDefaults.standard.bool(forKey: "autoFollowSessions") && appState.activeSessionID != newest.id && newest.isActive) {
                            switchLiveWatchTo(session: newest, watcher: watcher)
                        }
                    }
                }
            }
        }
    }

    @MainActor
    private func switchLiveWatchTo(session: SessionInfo, watcher: TelemetryWatcher) {
        watchingTask?.cancel()
        appState.activeSessionID = session.id
        appState.clearEvents()

        watchingTask = Task {
            let stream = await watcher.startWatching(fileURL: session.transcriptURL, readFromBeginning: true, maxInitialLines: 30)
            for await event in stream {
                await MainActor.run {
                    governor.notifyEventActivity()
                    director.handleEvent(event)
                    appState.appendEvent(event)
                    appState.activeModelName = director.activeModelName

                    if case .agentMessage(_, let text) = event {
                        appState.latestResponse = text
                    }

                    NotificationService.shared.handleEvent(event, isAppActive: NSApp.isActive)
                }
            }
        }
    }

    private func handleSelectSession(_ session: SessionInfo) {
        if appState.isLiveAntigravityMode, let watcher = telemetryWatcher {
            switchLiveWatchTo(session: session, watcher: watcher)
        } else {
            // Replay selected session
            loadSessionForReplay(session: session)
        }
    }

    private func loadSessionForReplay(session: SessionInfo) {
        let adapter = AntigravityAdapter()
        if let engine = try? ReplayEngine(transcriptURL: session.transcriptURL, adapter: adapter) {
            self.replayEngine = engine
            appState.activeSessionID = session.id
            appState.clearEvents()
            Task {
                let count = await engine.totalEvents
                await MainActor.run { appState.totalEvents = count }
            }
        }
    }

    private func setupReplayFixture() {
        let adapter = AntigravityAdapter()
        if let fixtureURL = ReplayEngine.defaultRecordingURL(),
           let engine = try? ReplayEngine(transcriptURL: fixtureURL, adapter: adapter) {
            self.replayEngine = engine
            Task {
                let count = await engine.totalEvents
                await MainActor.run { appState.totalEvents = count }
            }
        }
    }

    private func toggleLiveMode() {
        appState.isLiveAntigravityMode.toggle()
        appState.clearEvents()

        if appState.isLiveAntigravityMode {
            if let watcher = telemetryWatcher {
                startSessionMonitoringAndLiveWatch(watcher: watcher)
            }
        } else {
            sessionMonitorTask?.cancel()
            watchingTask?.cancel()
            Task {
                await telemetryWatcher?.stopWatching()
            }
            setupReplayFixture()
        }
    }

    private func handlePromptSubmit(_ prompt: String) {
        let userEvent = AgentEvent.userPrompt(text: prompt)
        appState.appendEvent(userEvent)
        director.handleEvent(userEvent)
        governor.notifyEventActivity()

        if appState.isLiveAntigravityMode {
            // Forward prompt seamlessly to active Antigravity session in background
            AntigravityBridge.forwardPromptToAntigravity(prompt)

            let thinkEvent = AgentEvent.thinking(agentID: "sovereign")
            appState.appendEvent(thinkEvent)
            director.handleEvent(thinkEvent)
        } else {
            // Replay/offline simulation for testing
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                let replyText = "Replay Mode: Quest '\(prompt)' acknowledged by the Sovereign Council."
                let msgEvent = AgentEvent.agentMessage(agentID: "sovereign", text: replyText)
                appState.appendEvent(msgEvent)
                director.handleEvent(msgEvent)
                appState.latestResponse = replyText
            }
        }
    }

    private func handleSelectSkill(_ skill: SkillWorkshop) {
        scene.focusLandmark(key: skill.districtID.rawValue)
        let event = AgentEvent.skillLoaded(agentID: "scribe", skillName: skill.name)
        appState.appendEvent(event)
        director.handleEvent(event)
    }

    private func handleSelectModel(_ model: String) {
        appState.activeModelName = model
        let event = AgentEvent.sessionStarted(sessionID: UUID().uuidString, model: model, startedAt: Date())
        appState.appendEvent(event)
        director.handleEvent(event)
    }

    private func updateWindowPinLevel(isPinned: Bool) {
        DispatchQueue.main.async {
            if let window = NSApp.windows.first {
                window.level = isPinned ? .floating : .normal
            }
        }
    }

    // MARK: - Replay Controls

    private func togglePlayPause() {
        guard let engine = replayEngine else { return }
        Task {
            let playing = await engine.currentlyPlaying
            if playing {
                await engine.pause()
                await MainActor.run { appState.isPlaying = false }
            } else {
                await engine.play()
                await MainActor.run { appState.isPlaying = true }
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
                    appState.appendEvent(event)
                    appState.activeModelName = director.activeModelName
                }
                let progress = await engine.currentProgress
                await MainActor.run {
                    appState.currentProgress = progress
                }
            }
            await MainActor.run { appState.isPlaying = false }
        }
    }

    private func stepForward() {
        guard let engine = replayEngine else { return }
        Task {
            if let event = await engine.stepForward() {
                await MainActor.run {
                    director.handleEvent(event)
                    appState.appendEvent(event)
                    appState.activeModelName = director.activeModelName
                }
                let progress = await engine.currentProgress
                await MainActor.run { appState.currentProgress = progress }
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
                await MainActor.run { appState.currentProgress = progress }
            }
        }
    }

    private func changeSpeed(_ speed: PlaybackSpeed) {
        appState.currentSpeed = speed
        guard let engine = replayEngine else { return }
        Task {
            await engine.setSpeed(speed)
        }
    }
}
