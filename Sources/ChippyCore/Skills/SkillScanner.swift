import Foundation

/// Scans directories for `SKILL.md` definitions and transforms them into `SkillWorkshop` models.
/// Tolerant of malformed syntax: invalid skills become "Ruins" in the diorama rather than crashing.
public struct SkillScanner: Sendable {
    private let parser: FrontmatterParser
    private let classifier: DistrictClassifier

    public init(
        parser: FrontmatterParser = FrontmatterParser(),
        classifier: DistrictClassifier = DistrictClassifier()
    ) {
        self.parser = parser
        self.classifier = classifier
    }

    /// Scans a single directory to see if it represents a skill (contains `SKILL.md`).
    public func scanSkillDirectory(at folderURL: URL, userOverrides: [String: DistrictID] = [:]) -> SkillWorkshop? {
        let skillFile = folderURL.appendingPathComponent("SKILL.md")
        guard FileManager.default.fileExists(atPath: skillFile.path) else {
            return nil
        }

        let folderName = folderURL.lastPathComponent

        guard let content = try? String(contentsOf: skillFile, encoding: .utf8) else {
            return SkillWorkshop(
                id: folderName,
                name: folderName,
                description: "Failed to read SKILL.md content from disk.",
                districtID: .wanderersMarket,
                directoryURL: folderURL,
                isRuined: true,
                parseError: "Unreadable file encoding or disk permission error"
            )
        }

        let parsed = parser.parse(markdown: content)

        if !parsed.isValid {
            return SkillWorkshop(
                id: folderName,
                name: parsed.name ?? folderName,
                description: parsed.description ?? "Malformed skill definition.",
                districtID: .wanderersMarket,
                directoryURL: folderURL,
                isRuined: true,
                parseError: parsed.parseError ?? "Invalid frontmatter syntax",
                metadata: parsed.metadata
            )
        }

        let name = parsed.name ?? folderName
        let description = parsed.description ?? ""
        let districtID = classifier.classify(
            skillID: folderName,
            name: name,
            description: description,
            explicitDistrict: parsed.district,
            userOverrides: userOverrides
        )

        return SkillWorkshop(
            id: folderName,
            name: name,
            description: description,
            districtID: districtID,
            directoryURL: folderURL,
            isRuined: false,
            parseError: nil,
            explicitDistrict: parsed.district,
            metadata: parsed.metadata,
            directivesBody: parsed.body
        )
    }

    /// Recursively or flatly scans a parent container directory (e.g. `.../.agents/skills`)
    /// and returns all discovered `SkillWorkshop` instances.
    public func scanContainerDirectory(at rootURL: URL, userOverrides: [String: DistrictID] = [:]) -> [SkillWorkshop] {
        var workshops: [SkillWorkshop] = []
        let fileManager = FileManager.default

        guard let items = try? fileManager.contentsOfDirectory(at: rootURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else {
            return []
        }

        for item in items {
            var isDir: ObjCBool = false
            if fileManager.fileExists(atPath: item.path, isDirectory: &isDir), isDir.boolValue {
                if let workshop = scanSkillDirectory(at: item, userOverrides: userOverrides) {
                    workshops.append(workshop)
                }
            }
        }

        return workshops.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
