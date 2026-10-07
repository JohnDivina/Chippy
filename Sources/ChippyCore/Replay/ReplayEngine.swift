import Foundation

/// Playback speed multipliers supported by the ReplayEngine.
public enum PlaybackSpeed: Double, Sendable, CaseIterable {
    case half = 0.5
    case normal = 1.0
    case double = 2.0
    case quadruple = 4.0
    case octuple = 8.0

    public var displayLabel: String {
        switch self {
        case .half: return "0.5×"
        case .normal: return "1.0×"
        case .double: return "2.0×"
        case .quadruple: return "4.0×"
        case .octuple: return "8.0×"
        }
    }
}

/// Actor driving historical session replay for tests, demos, and onboarding.
public actor ReplayEngine {
    private let events: [AgentEvent]
    private var currentIndex: Int = 0
    private var isPlaying: Bool = false
    private var playbackSpeed: PlaybackSpeed = .normal
    private var playbackTask: Task<Void, Never>?

    private var continuation: AsyncStream<AgentEvent>.Continuation?

    public init(events: [AgentEvent]) {
        self.events = events
    }

    /// Initializes ReplayEngine by parsing lines from a transcript file with an adapter.
    public init(transcriptURL: URL, adapter: any TranscriptAdapter, redactor: Redactor = Redactor()) throws {
        let content = try String(contentsOf: transcriptURL, encoding: .utf8)
        let lines = content.components(separatedBy: "\n")
        var collected: [AgentEvent] = []

        for line in lines where !line.trimmingCharacters(in: .whitespaces).isEmpty {
            if let data = line.data(using: .utf8), let lineEvents = try? adapter.events(fromLine: data) {
                for ev in lineEvents {
                    collected.append(redactor.redact(event: ev))
                }
            }
        }

        self.events = collected
    }

    /// Returns the full stream of events emitted during playback.
    public func makeEventStream() -> AsyncStream<AgentEvent> {
        AsyncStream { continuation in
            self.continuation = continuation
        }
    }

    public var totalEvents: Int {
        events.count
    }

    public var currentProgress: Int {
        currentIndex
    }

    public var currentlyPlaying: Bool {
        isPlaying
    }

    public var currentSpeed: PlaybackSpeed {
        playbackSpeed
    }

    /// Starts or resumes playback.
    public func play() {
        guard !isPlaying, currentIndex < events.count else { return }
        isPlaying = true

        playbackTask = Task { [weak self] in
            guard let self else { return }
            while await self.currentlyPlaying {
                guard let nextEvent = await self.advance() else {
                    await self.pause()
                    break
                }

                await self.continuation?.yield(nextEvent)

                let speed = await self.currentSpeed.rawValue
                let baseDelayNanos: UInt64 = 500_000_000 // 0.5s base delay between events
                let delayNanos = UInt64(Double(baseDelayNanos) / speed)

                try? await Task.sleep(nanoseconds: delayNanos)
            }
        }
    }

    /// Pauses current playback.
    public func pause() {
        isPlaying = false
        playbackTask?.cancel()
        playbackTask = nil
    }

    /// Changes the playback speed multiplier.
    public func setSpeed(_ speed: PlaybackSpeed) {
        self.playbackSpeed = speed
    }

    /// Scrubs to a specific event index.
    public func seek(to index: Int) -> AgentEvent? {
        guard !events.isEmpty else { return nil }
        let clamped = max(0, min(index, events.count - 1))
        currentIndex = clamped
        let targetEvent = events[clamped]
        continuation?.yield(targetEvent)
        return targetEvent
    }

    /// Advances by one step manually.
    public func stepForward() -> AgentEvent? {
        advance()
    }

    /// Steps backward by one event.
    public func stepBackward() -> AgentEvent? {
        guard currentIndex > 0 else { return nil }
        currentIndex -= 1
        let event = events[currentIndex]
        continuation?.yield(event)
        return event
    }

    private func advance() -> AgentEvent? {
        guard currentIndex < events.count else { return nil }
        let event = events[currentIndex]
        currentIndex += 1
        return event
    }

    /// Helper locating bundled recordings for Replay mode.
    public static func defaultRecordingURL() -> URL? {
        if let url = Bundle.module.url(forResource: "session_01_portfolio", withExtension: "jsonl") {
            return url
        }
        let fallback = URL(fileURLWithPath: "Resources/Recordings/session_01_portfolio.jsonl")
        return FileManager.default.fileExists(atPath: fallback.path) ? fallback : nil
    }
}
