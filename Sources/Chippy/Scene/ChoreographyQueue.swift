import Foundation
import SpriteKit
import ChippyCore

/// A discrete scheduled animation action assigned to a familiar.
public struct ChoreographyAction: @unchecked Sendable {
    public let familiar: FamiliarKind
    public let taskName: String
    public let targetLandmark: String?
    public let targetGrid: GridPoint?
    public let duration: TimeInterval
    public let skipWalk: Bool

    public init(
        familiar: FamiliarKind,
        taskName: String,
        targetLandmark: String? = nil,
        targetGrid: GridPoint? = nil,
        duration: TimeInterval = 2.0,
        skipWalk: Bool = false
    ) {
        self.familiar = familiar
        self.taskName = taskName
        self.targetLandmark = targetLandmark
        self.targetGrid = targetGrid
        self.duration = duration
        self.skipWalk = skipWalk
    }
}

/// `@MainActor` per-familiar FIFO queue manager that coalesces high-frequency events,
/// throttles adaptive animation speeds under heavy workloads, and independently resets
/// idle workshop signboards without cancelling concurrent tasks.
@MainActor
public final class ChoreographyQueue {
    public weak var scene: ParadiseScene?

    private var queues: [FamiliarKind: [ChoreographyAction]] = [:]
    private var isBusy: [FamiliarKind: Bool] = [:]
    private var workshopActivity: [String: Date] = [:]
    private var workshopIdleTask: Task<Void, Never>?

    public init(scene: ParadiseScene? = nil) {
        self.scene = scene
        startWorkshopIdleTimer()
    }

    deinit {
        workshopIdleTask?.cancel()
    }

    /// Enqueues an action for a familiar. Dispatches immediately if idle, or queues if busy.
    public func enqueue(_ action: ChoreographyAction) {
        var queue = queues[action.familiar] ?? []
        queue.append(action)
        queues[action.familiar] = queue

        pumpNext(for: action.familiar)
    }

    /// Marks a workshop active with a timestamp so it resets to peaceful idle after 4s of quiet.
    public func recordWorkshopActivity(landmarkKey: String, taskName: String) {
        workshopActivity[landmarkKey] = Date()
        scene?.setWorkshopWorking(key: landmarkKey, isWorking: true, task: taskName)
    }

    private func pumpNext(for familiar: FamiliarKind) {
        guard isBusy[familiar] != true else { return }
        guard var queue = queues[familiar], !queue.isEmpty else { return }

        let action = queue.removeFirst()
        queues[familiar] = queue
        isBusy[familiar] = true

        let count = queue.count
        let speedMultiplier: Double = count > 15 ? 0.25 : (count > 5 ? 0.5 : 1.0)
        let effectiveDuration = action.duration * speedMultiplier
        let shouldSkipWalk = action.skipWalk || count > 15

        if let landmark = action.targetLandmark, let grid = action.targetGrid, !shouldSkipWalk {
            scene?.moveFamiliar(familiar, toLandmark: landmark, targetGrid: grid) { [weak self] in
                self?.scene?.familiarNode(for: familiar)?.performWork(taskName: action.taskName, duration: effectiveDuration) {
                    self?.isBusy[familiar] = false
                    self?.pumpNext(for: familiar)
                }
            }
        } else {
            scene?.familiarNode(for: familiar)?.performWork(taskName: action.taskName, duration: effectiveDuration) { [weak self] in
                self?.isBusy[familiar] = false
                self?.pumpNext(for: familiar)
            }
        }
    }

    private func startWorkshopIdleTimer() {
        workshopIdleTask?.cancel()
        workshopIdleTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled, let self else { break }
                self.checkWorkshopTimeouts()
            }
        }
    }

    private func checkWorkshopTimeouts() {
        let now = Date()
        for (key, lastTime) in workshopActivity {
            if now.timeIntervalSince(lastTime) >= 4.0 {
                scene?.setWorkshopWorking(key: key, isWorking: false)
                workshopActivity.removeValue(forKey: key)
            }
        }
    }
}
