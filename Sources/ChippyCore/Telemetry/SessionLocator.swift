import Foundation

/// Locates active or recent Antigravity session transcripts on the local Mac.
public struct SessionLocator: Sendable {
    public init() {}

    /// Finds the most recently modified `transcript.jsonl` in the Antigravity brain storage.
    public func findLatestTranscriptURL(baseBrainURL: URL? = nil) -> URL? {
        let brainDir = baseBrainURL ?? FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".gemini/antigravity-ide/brain")

        let fileManager = FileManager.default
        guard let sessionFolders = try? fileManager.contentsOfDirectory(
            at: brainDir,
            includingPropertiesForKeys: [.contentModificationDateKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }

        var candidateTranscripts: [(url: URL, date: Date)] = []

        for folder in sessionFolders {
            let transcriptURL = folder
                .appendingPathComponent(".system_generated/logs/transcript.jsonl")

            if fileManager.fileExists(atPath: transcriptURL.path) {
                if let attrs = try? fileManager.attributesOfItem(atPath: transcriptURL.path),
                   let modDate = attrs[.modificationDate] as? Date {
                    candidateTranscripts.append((url: transcriptURL, date: modDate))
                }
            }
        }

        // Return the most recently updated transcript
        candidateTranscripts.sort { $0.date > $1.date }
        return candidateTranscripts.first?.url
    }
}
