import Foundation

/// Data structure matching the bundled `districts.json` configuration.
private struct DistrictConfig: Codable {
    struct KeywordRule: Codable {
        let district: String
        let keywords: [String]
    }

    let exactSkillMappings: [String: String]
    let keywordRules: [KeywordRule]
    let fallbackDistrict: String
}

/// Classifies skills into their designated island districts.
/// Supports frontmatter overrides, user settings overrides, bundled keyword rules,
/// and fallback to The Wanderer's Market.
public final class DistrictClassifier: Sendable {
    private let exactSkillMappings: [String: DistrictID]
    private let keywordRules: [(district: DistrictID, keywords: [String])]
    private let fallbackDistrict: DistrictID

    public init(configURL: URL? = nil) {
        var mappings: [String: DistrictID] = [:]
        var rules: [(district: DistrictID, keywords: [String])] = []
        var fallback: DistrictID = .wanderersMarket

        let resolvedURL = configURL ?? Bundle.module.url(forResource: "districts", withExtension: "json")

        if let url = resolvedURL, let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode(DistrictConfig.self, from: data) {
            for (k, v) in decoded.exactSkillMappings {
                if let dist = DistrictID(rawValue: v) {
                    mappings[k] = dist
                }
            }
            for rule in decoded.keywordRules {
                if let dist = DistrictID(rawValue: rule.district) {
                    rules.append((district: dist, keywords: rule.keywords))
                }
            }
            if let f = DistrictID(rawValue: decoded.fallbackDistrict) {
                fallback = f
            }
        } else {
            // Built-in hardcoded fallback mappings if bundle resource is absent
            mappings = Self.defaultExactMappings
            rules = Self.defaultKeywordRules
            fallback = .wanderersMarket
        }

        self.exactSkillMappings = mappings
        self.keywordRules = rules
        self.fallbackDistrict = fallback
    }

    /// Classifies a skill into a target district.
    /// Priority:
    /// 1. User override (from settings)
    /// 2. Explicit frontmatter `district:` declaration
    /// 3. Exact skill ID lookup
    /// 4. Keyword heuristic on name & description
    /// 5. Fallback -> Wanderer's Market
    public func classify(
        skillID: String,
        name: String,
        description: String,
        explicitDistrict: String? = nil,
        userOverrides: [String: DistrictID] = [:]
    ) -> DistrictID {
        // 1. User manual override
        if let override = userOverrides[skillID] {
            return override
        }

        // 2. Explicit frontmatter district
        if let explicit = explicitDistrict?.trimmingCharacters(in: .whitespacesAndNewlines), !explicit.isEmpty {
            if let dist = DistrictID(rawValue: explicit) {
                return dist
            }
            // Also check friendly matching
            for dist in DistrictID.allCases {
                if dist.rawValue.replacingOccurrences(of: "_", with: "-") == explicit.lowercased() ||
                   dist.rawValue == explicit.lowercased() {
                    return dist
                }
            }
        }

        // 3. Exact skill ID lookup
        let normalizedID = skillID.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if let exact = exactSkillMappings[normalizedID] {
            return exact
        }

        // 4. Keyword heuristic matching
        let searchCorpus = "\(normalizedID) \(name.lowercased()) \(description.lowercased())"
        for rule in keywordRules {
            for keyword in rule.keywords {
                if searchCorpus.contains(keyword.lowercased()) {
                    return rule.district
                }
            }
        }

        // 5. Fallback
        return fallbackDistrict
    }

    private static let defaultExactMappings: [String: DistrictID] = [
        "coordinator-mode": .highCouncil,
        "parallel-agents": .highCouncil,
        "plan-writing": .highCouncil,
        "brainstorming": .highCouncil,
        "architecture": .highCouncil,
        "context-compression": .highCouncil,
        "intelligent-routing": .highCouncil,
        "behavioral-modes": .highCouncil,
        "batch-operations": .highCouncil,
        "memory-system": .highCouncil,

        "security-hardening": .ironBastion,
        "vulnerability-scanner": .ironBastion,
        "red-team-tactics": .ironBastion,
        "tdd-workflow": .ironBastion,
        "testing-patterns": .ironBastion,
        "lint-and-validate": .ironBastion,
        "code-review-checklist": .ironBastion,
        "code-review-graph": .ironBastion,
        "verify-changes": .ironBastion,
        "webapp-testing": .ironBastion,
        "performance-profiling": .ironBastion,

        "frontend-design": .grandAtelier,
        "design-spec": .grandAtelier,
        "nextjs-react-expert": .grandAtelier,
        "tailwind-patterns": .grandAtelier,
        "web-design-guidelines": .grandAtelier,
        "mobile-design": .grandAtelier,
        "frontend-architecture": .grandAtelier,
        "game-development": .grandAtelier,
        "i18n-localization": .grandAtelier,
        "seo-fundamentals": .grandAtelier,
        "geo-fundamentals": .grandAtelier,

        "database-design": .engineCore,
        "api-patterns": .engineCore,
        "server-management": .engineCore,
        "deployment-procedures": .engineCore,
        "bash-linux": .engineCore,
        "powershell-windows": .engineCore,
        "nodejs-best-practices": .engineCore,
        "python-patterns": .engineCore,
        "rust-pro": .engineCore,
        "clean-code": .engineCore,
        "simplify-code": .engineCore,
        "systematic-debugging": .engineCore,

        "documentation-templates": .scriptorium,
        "app-builder": .scriptorium,
        "mcp-builder": .scriptorium,
        "skillify": .scriptorium
    ]

    private static let defaultKeywordRules: [(district: DistrictID, keywords: [String])] = [
        (.highCouncil, ["coordinat", "orchestrat", "planning", "brainstorm", "routing", "context", "memory", "agent"]),
        (.ironBastion, ["security", "vulnerability", "audit", "test", "tdd", "lint", "review", "verify", "red-team", "profiling"]),
        (.grandAtelier, ["frontend", "ui", "ux", "design", "tailwind", "css", "react", "nextjs", "mobile", "layout"]),
        (.engineCore, ["database", "sql", "postgres", "api", "server", "linux", "bash", "deploy", "backend", "python", "rust", "debug"]),
        (.scriptorium, ["doc", "template", "mcp", "skillify", "builder", "spec"])
    ]
}
