import Foundation

/// Discovers skill workshop folders across user-specified paths, standard system locations,
/// and bundled fallback samples.
public final class SkillDiscovery: Sendable {
    private let scanner: SkillScanner

    public init(scanner: SkillScanner = SkillScanner()) {
        self.scanner = scanner
    }

    /// Discovers all available skills according to defined priority order:
    /// 1. User configured folders (Settings)
    /// 2. Workspace & home directory standards (`.agents/skills`, `~/.gemini/config/skills`, etc.)
    /// 3. Bundled sample skills fallback
    public func discoverSkills(
        userCustomFolders: [URL] = [],
        workspaceURL: URL? = nil,
        userOverrides: [String: DistrictID] = [:]
    ) -> [SkillWorkshop] {
        var discoveredIDs: Set<String> = []
        var finalWorkshops: [SkillWorkshop] = []

        var candidateDirectories: [URL] = []

        // 1. User custom folders take top precedence
        candidateDirectories.append(contentsOf: userCustomFolders)

        // 2. Common workspace and system paths
        if let workspace = workspaceURL {
            candidateDirectories.append(workspace.appendingPathComponent(".agents/skills"))
            candidateDirectories.append(workspace.appendingPathComponent(".claude/skills"))
        }

        let fileManager = FileManager.default
        let homeDirectory = fileManager.homeDirectoryForCurrentUser

        // Standard global locations
        candidateDirectories.append(homeDirectory.appendingPathComponent(".gemini/config/skills"))
        candidateDirectories.append(homeDirectory.appendingPathComponent(".claude/skills"))
        candidateDirectories.append(homeDirectory.appendingPathComponent(".agents/skills"))

        // Also check if production-agents is nearby in parent directory
        if let workspace = workspaceURL {
            let nearbyProduction = workspace.deletingLastPathComponent().appendingPathComponent("production-agents/.agents/skills")
            candidateDirectories.append(nearbyProduction)
        }

        // 3. Scan candidate directories
        for dir in candidateDirectories {
            guard fileManager.fileExists(atPath: dir.path) else { continue }
            let workshops = scanner.scanContainerDirectory(at: dir, userOverrides: userOverrides)
            for workshop in workshops {
                if !discoveredIDs.contains(workshop.id) {
                    discoveredIDs.insert(workshop.id)
                    finalWorkshops.append(workshop)
                }
            }
        }

        // 4. Bundled samples if island would otherwise be empty
        if finalWorkshops.isEmpty {
            if let sampleURL = Bundle.module.url(forResource: "SampleSkills", withExtension: nil) {
                let samples = scanner.scanContainerDirectory(at: sampleURL, userOverrides: userOverrides)
                for workshop in samples {
                    if !discoveredIDs.contains(workshop.id) {
                        discoveredIDs.insert(workshop.id)
                        finalWorkshops.append(workshop)
                    }
                }
            }
        }

        return finalWorkshops.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
