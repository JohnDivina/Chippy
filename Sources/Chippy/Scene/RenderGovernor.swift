import AppKit
import SpriteKit
import SwiftUI

/// `@MainActor` governor controlling frame rates, window occlusion pauses, and idle throttling
/// to eliminate `SKView: no drawables available` warnings and reduce idle CPU footprint to < 2%.
@MainActor
public final class RenderGovernor: ObservableObject {
    public weak var skView: SKView?
    public weak var scene: SKScene?

    private var lastEventTime: Date = Date()
    private var idleTask: Task<Void, Never>?
    private var isWindowVisible: Bool = true

    public init() {
        setupWindowNotifications()
        startIdleMonitoring()
    }

    deinit {
        idleTask?.cancel()
    }

    /// Notifies the governor that live telemetry activity has arrived, instantly ramping back to 60 FPS.
    public func notifyEventActivity() {
        lastEventTime = Date()
        resumeActiveRendering()
    }

    /// Attaches the managed SKView and scene.
    public func attach(skView: SKView, scene: SKScene) {
        self.skView = skView
        self.scene = scene
        skView.preferredFramesPerSecond = 60
        skView.isPaused = false
    }

    private func setupWindowNotifications() {
        NotificationCenter.default.addObserver(
            forName: NSWindow.didChangeOcclusionStateNotification,
            object: nil,
            queue: .main
        ) { [weak self] notif in
            guard let window = notif.object as? NSWindow else { return }
            Task { @MainActor [weak self] in
                self?.handleWindowOcclusion(window: window)
            }
        }

        NotificationCenter.default.addObserver(
            forName: NSWindow.didMiniaturizeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.pauseRendering()
            }
        }

        NotificationCenter.default.addObserver(
            forName: NSWindow.didDeminiaturizeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notif in
            guard let window = notif.object as? NSWindow else { return }
            Task { @MainActor [weak self] in
                self?.handleWindowOcclusion(window: window)
            }
        }
    }

    private func handleWindowOcclusion(window: NSWindow) {
        let isVisible = window.occlusionState.contains(.visible)
        self.isWindowVisible = isVisible
        if !isVisible {
            pauseRendering()
        } else {
            resumeActiveRendering()
        }
    }

    private func startIdleMonitoring() {
        idleTask?.cancel()
        idleTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                guard !Task.isCancelled, let self else { break }
                self.evaluateIdleState()
            }
        }
    }

    private func evaluateIdleState() {
        guard isWindowVisible else { return }
        let idleSeconds = Date().timeIntervalSince(lastEventTime)

        if idleSeconds > 120 {
            // Idle for 2+ minutes: pause rendering
            skView?.isPaused = true
        } else if idleSeconds > 20 {
            // Idle for 20 seconds: lower to 15 FPS
            skView?.preferredFramesPerSecond = 15
        } else {
            skView?.preferredFramesPerSecond = 60
            skView?.isPaused = false
        }
    }

    private func pauseRendering() {
        skView?.isPaused = true
        scene?.isPaused = true
    }

    private func resumeActiveRendering() {
        guard isWindowVisible else { return }
        skView?.isPaused = false
        scene?.isPaused = false
        skView?.preferredFramesPerSecond = 60
    }
}
