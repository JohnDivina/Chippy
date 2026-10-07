import Foundation

/// Metadata descriptor for a detected Antigravity session transcript.
public struct SessionInfo: Sendable, Identifiable, Equatable {
    public let id: String
    public let transcriptURL: URL
    public let lastModified: Date
    public let isActive: Bool

    public var displayName: String {
        String(id.prefix(8))
    }

    public init(id: String, transcriptURL: URL, lastModified: Date, isActive: Bool) {
        self.id = id
        self.transcriptURL = transcriptURL
        self.lastModified = lastModified
        self.isActive = isActive
    }
}

/// Actor monitoring `~/.gemini/antigravity-ide/brain` for new or recently updated conversations.
/// Publishes an AsyncStream of available sessions and detects when a new session should be followed.
public actor SessionMonitor {
    private let brainDir: URL
    private var isMonitoring: Bool = false
    private var monitorTask: Task<Void, Never>?
    private var continuation: AsyncStream<[SessionInfo]>.Continuation?

    public init(baseBrainURL: URL? = nil) {
        self.brainDir = baseBrainURL ?? FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".gemini/antigravity-ide/brain")
    }

    /// Scans the brain directory and returns all discoverable sessions sorted by modification date.
    public func scanSessions() -> [SessionInfo] {
        let fileManager = FileManager.default
        guard let sessionFolders = try? fileManager.contentsOfDirectory(
            at: brainDir,
            includingPropertiesForKeys: [.contentModificationDateKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var results: [SessionInfo] = []
        let now = Date()

        for folder in sessionFolders {
            let sessionID = folder.lastPathComponent
            let transcriptURL = folder.appendingPathComponent(".system_generated/logs/transcript.jsonl")

            if fileManager.fileExists(atPath: transcriptURL.path),
               let attrs = try? fileManager.attributesOfItem(atPath: transcriptURL.path),
               let modDate = attrs[.modificationDate] as? Date {
                let isActive = now.timeIntervalSince(modDate) < 120 // Modified in last 2 mins
                results.append(SessionInfo(
                    id: sessionID,
                    transcriptURL: transcriptURL,
                    lastModified: modDate,
                    isActive: isActive
                ))
            }
        }

        results.sort { $0.lastModified > $1.lastModified }
        return results
    }

    /// Starts continuously observing the brain directory for session creation and activity updates.
    public func startMonitoring(pollIntervalSeconds: Double = 2.0) -> AsyncStream<[SessionInfo]> {
        stopMonitoring()
        self.isMonitoring = true

        let stream = AsyncStream<[SessionInfo]> { cont in
            self.continuation = cont
        }

        // Initial emission
        let initial = scanSessions()
        continuation?.yield(initial)

        monitorTask = Task { [weak self] in
            guard let self else { return }
            while await self.isMonitoringState() {
                try? await Task.sleep(nanoseconds: UInt64(pollIntervalSeconds * 1_000_000_000))
                guard await self.isMonitoringState() else { break }
                let current = await self.scanSessions()
                await self.continuation?.yield(current)
            }
        }

        return stream
    }

    public func stopMonitoring() {
        self.isMonitoring = false
        monitorTask?.cancel()
        monitorTask = nil
        continuation?.finish()
        continuation = nil
    }

    private func isMonitoringState() -> Bool {
        isMonitoring
    }
}
