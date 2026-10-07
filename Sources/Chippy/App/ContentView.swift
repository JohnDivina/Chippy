import SwiftUI
import SpriteKit
import ChippyCore

/// Root view assembling the 2.5D SpriteKit diorama canvas and SwiftUI HUD overlay.
public struct ContentView: View {
    @State private var scene: ParadiseScene
    @State private var director: SceneDirector
    @State private var replayEngine: ReplayEngine?

    @State private var activeModelName: String = "Observing Model..."
    @State private var isPlaying: Bool = false
    @State private var currentSpeed: PlaybackSpeed = .normal
    @State private var currentProgress: Int = 0
    @State private var totalEvents: Int = 0
    @State private var loadedSkillCount: Int = 0
    @State private var eventLog: [AgentEvent] = []

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
                DragGesture()
                    .onChanged { value in
                        scene.panCamera(by: CGPoint(
                            x: value.translation.width * 0.5,
                            y: -value.translation.height * 0.5
                        ))
                    }
            )

            // Anti-slop SwiftUI HUD
            ChippyHUDView(
                activeModelName: $activeModelName,
                isPlaying: $isPlaying,
                currentSpeed: $currentSpeed,
                currentProgress: $currentProgress,
                totalEvents: totalEvents,
                loadedSkillCount: loadedSkillCount,
                events: eventLog,
                onPlayPause: togglePlayPause,
                onStepForward: stepForward,
                onStepBackward: stepBackward,
                onSpeedChange: changeSpeed,
                onResetCamera: { scene.resetCamera() }
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
        // 1. Ingest production skills
        let discovery = SkillDiscovery()
        let discoveredSkills = discovery.discoverSkills(
            workspaceURL: URL(fileURLWithPath: "/Users/johnrey/Desktop/Programming")
        )
        self.loadedSkillCount = discoveredSkills.count

        // 2. Initialize ReplayEngine with bundled portfolio session fixture
        let adapter = AntigravityAdapter()
        if let fixtureURL = ReplayEngine.defaultRecordingURL(),
           let engine = try? ReplayEngine(transcriptURL: fixtureURL, adapter: adapter) {
            self.replayEngine = engine
            self.totalEvents = await engine.totalEvents
        }
    }

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
