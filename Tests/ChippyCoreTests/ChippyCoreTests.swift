import XCTest
import Foundation
@testable import ChippyCore

final class FrontmatterParserTests: XCTestCase {
    let parser = FrontmatterParser()

    func testValidFrontmatter() {
        let md = """
        ---
        name: security-hardening
        description: Enforces RLS, rate limiting, and IDOR defenses.
        district: iron_bastion
        ---

        # Security Hardening
        Body content here.
        """

        let result = parser.parse(markdown: md)
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.name, "security-hardening")
        XCTAssertEqual(result.description, "Enforces RLS, rate limiting, and IDOR defenses.")
        XCTAssertEqual(result.district, "iron_bastion")
        XCTAssertNil(result.parseError)
        XCTAssertTrue(result.body.contains("Body content here."))
    }

    func testMultilineDescription() {
        let md = """
        ---
        name: "complex-coordinator"
        description: >
          Orchestrates multiple worker agents
          across diverse parallel tasks.
        ---
        """

        let result = parser.parse(markdown: md)
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.name, "complex-coordinator")
        XCTAssertTrue(result.description?.contains("Orchestrates multiple worker agents") == true)
    }

    func testMissingDelimiter() {
        let md = "# Just Markdown without frontmatter"
        let result = parser.parse(markdown: md)
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.parseError)
    }

    func testUnclosedFrontmatter() {
        let md = """
        ---
        name: broken-skill
        description: forgot to close delimiter
        """
        let result = parser.parse(markdown: md)
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.parseError)
    }
}

final class DistrictClassifierTests: XCTestCase {
    let classifier = DistrictClassifier()

    func test48ProductionSkillsClassification() {
        // 1. The High Council (10)
        let highCouncilSkills = [
            "coordinator-mode", "parallel-agents", "plan-writing", "brainstorming", "architecture",
            "context-compression", "intelligent-routing", "behavioral-modes", "batch-operations", "memory-system"
        ]
        for skill in highCouncilSkills {
            let district = classifier.classify(skillID: skill, name: skill, description: "")
            XCTAssertEqual(district, .highCouncil, "Expected \(skill) to be highCouncil, got \(district)")
        }

        // 2. The Iron Bastion (11)
        let ironBastionSkills = [
            "security-hardening", "vulnerability-scanner", "red-team-tactics", "tdd-workflow",
            "testing-patterns", "lint-and-validate", "code-review-checklist", "code-review-graph",
            "verify-changes", "webapp-testing", "performance-profiling"
        ]
        for skill in ironBastionSkills {
            let district = classifier.classify(skillID: skill, name: skill, description: "")
            XCTAssertEqual(district, .ironBastion, "Expected \(skill) to be ironBastion, got \(district)")
        }

        // 3. The Grand Atelier (11)
        let grandAtelierSkills = [
            "frontend-design", "design-spec", "nextjs-react-expert", "tailwind-patterns",
            "web-design-guidelines", "mobile-design", "frontend-architecture", "game-development",
            "i18n-localization", "seo-fundamentals", "geo-fundamentals"
        ]
        for skill in grandAtelierSkills {
            let district = classifier.classify(skillID: skill, name: skill, description: "")
            XCTAssertEqual(district, .grandAtelier, "Expected \(skill) to be grandAtelier, got \(district)")
        }

        // 4. The Engine Core (12)
        let engineCoreSkills = [
            "database-design", "api-patterns", "server-management", "deployment-procedures",
            "bash-linux", "powershell-windows", "nodejs-best-practices", "python-patterns",
            "rust-pro", "clean-code", "simplify-code", "systematic-debugging"
        ]
        for skill in engineCoreSkills {
            let district = classifier.classify(skillID: skill, name: skill, description: "")
            XCTAssertEqual(district, .engineCore, "Expected \(skill) to be engineCore, got \(district)")
        }

        // 5. The Scriptorium (4)
        let scriptoriumSkills = [
            "documentation-templates", "app-builder", "mcp-builder", "skillify"
        ]
        for skill in scriptoriumSkills {
            let district = classifier.classify(skillID: skill, name: skill, description: "")
            XCTAssertEqual(district, .scriptorium, "Expected \(skill) to be scriptorium, got \(district)")
        }
    }

    func testFallbackToWanderersMarket() {
        let district = classifier.classify(
            skillID: "quantum-teleportation-gizmo",
            name: "Quantum Gizmo",
            description: "An exotic unclassified capability."
        )
        XCTAssertEqual(district, .wanderersMarket)
    }

    func testExplicitDistrictOverride() {
        let district = classifier.classify(
            skillID: "database-design",
            name: "database-design",
            description: "Postgres schema design",
            explicitDistrict: "grand_atelier"
        )
        XCTAssertEqual(district, .grandAtelier)
    }

    func testUserOverridePriority() {
        let overrides: [String: DistrictID] = ["database-design": .highCouncil]
        let district = classifier.classify(
            skillID: "database-design",
            name: "database-design",
            description: "Postgres schema design",
            explicitDistrict: "grand_atelier",
            userOverrides: overrides
        )
        XCTAssertEqual(district, .highCouncil)
    }
}

final class SkillScannerTests: XCTestCase {
    let scanner = SkillScanner()

    func testScanValidSkill() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let skillDir = tempDir.appendingPathComponent("audit-bot")
        try FileManager.default.createDirectory(at: skillDir, withIntermediateDirectories: true)

        let skillMD = """
        ---
        name: audit-bot
        description: Audits code for security vulnerabilities.
        ---
        # Audit Bot
        """
        try skillMD.write(to: skillDir.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)

        let workshop = scanner.scanSkillDirectory(at: skillDir)
        XCTAssertNotNil(workshop)
        XCTAssertEqual(workshop?.name, "audit-bot")
        XCTAssertEqual(workshop?.districtID, .ironBastion)
        XCTAssertEqual(workshop?.isRuined, false)
    }

    func testScanMalformedSkill() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let skillDir = tempDir.appendingPathComponent("corrupted-bot")
        try FileManager.default.createDirectory(at: skillDir, withIntermediateDirectories: true)

        let brokenMD = "No frontmatter whatsoever"
        try brokenMD.write(to: skillDir.appendingPathComponent("SKILL.md"), atomically: true, encoding: .utf8)

        let workshop = scanner.scanSkillDirectory(at: skillDir)
        XCTAssertNotNil(workshop)
        XCTAssertEqual(workshop?.isRuined, true)
        XCTAssertNotNil(workshop?.parseError)
    }

    func testRealProductionAgentsSkillsDirectory() {
        let productionAgentsURL = URL(fileURLWithPath: "/Users/johnrey/Desktop/Programming/production-agents/.agents/skills")
        guard FileManager.default.fileExists(atPath: productionAgentsURL.path) else {
            return
        }

        let workshops = scanner.scanContainerDirectory(at: productionAgentsURL)
        XCTAssertEqual(workshops.count, 48, "Expected exactly 48 production skills to be loaded, found \(workshops.count)")

        for workshop in workshops {
            XCTAssertFalse(workshop.isRuined, "Skill \(workshop.id) should not be marked as ruined")
            XCTAssertFalse(workshop.name.isEmpty, "Skill \(workshop.id) name must not be empty")
            XCTAssertNotEqual(workshop.districtID, .wanderersMarket, "Known production skill \(workshop.id) should map to a defined district")
        }
    }
}

final class RedactorTests: XCTestCase {
    let redactor = Redactor()

    func testMasksKnownSecretTokens() {
        let input = """
        Here is the key: sk-proj-1234567890abcdef1234567890 and Google AIzaSyD1234567890abcdef123456789012345
        Also GitHub: ghp_1234567890abcdef1234567890abcdef1234 and Slack: xoxb-123456789012-abcdef
        """
        let redacted = redactor.redact(input)
        XCTAssertFalse(redacted.contains("sk-proj-1234567890abcdef1234567890"))
        XCTAssertFalse(redacted.contains("AIzaSyD1234567890abcdef123456789012345"))
        XCTAssertFalse(redacted.contains("ghp_1234567890abcdef1234567890abcdef1234"))
        XCTAssertFalse(redacted.contains("xoxb-123456789012-abcdef"))
        XCTAssertTrue(redacted.contains("[REDACTED_OPENAI_KEY]"))
        XCTAssertTrue(redacted.contains("[REDACTED_GOOGLE_KEY]"))
        XCTAssertTrue(redacted.contains("[REDACTED_GITHUB_TOKEN]"))
        XCTAssertTrue(redacted.contains("[REDACTED_SLACK_TOKEN]"))

        // Anthropic, AWS, and JWT tests
        let cloudInput = "Anthropic: sk-ant-api03-1234567890abcdef12345678 and AWS: AKIAIOSFODNN7EXAMPLE and JWT: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
        let cloudRedacted = redactor.redact(cloudInput)
        XCTAssertTrue(cloudRedacted.contains("[REDACTED_ANTHROPIC_KEY]"))
        XCTAssertTrue(cloudRedacted.contains("[REDACTED_AWS_KEY]"))
        XCTAssertTrue(cloudRedacted.contains("[REDACTED_JWT]"))
        XCTAssertFalse(cloudRedacted.contains("AKIAIOSFODNN7EXAMPLE"))
    }

    func testMasksAuthorizationHeadersAndEnvSecrets() {
        let text = "Authorization: Bearer mySecretToken12345\nAPI_KEY='super_secret_production_key'"
        let redacted = redactor.redact(text)
        XCTAssertTrue(redacted.contains("Authorization: [REDACTED_AUTH]"))
        XCTAssertTrue(redacted.contains("API_KEY=[REDACTED]"))
        XCTAssertFalse(redacted.contains("super_secret_production_key"))
    }

    func testRedactsAgentEventPayloads() {
        let event = AgentEvent.commandRun(agentID: "lead", command: "export API_KEY=secret_key_12345678")
        let redactedEvent = redactor.redact(event: event)
        if case .commandRun(_, let cmd) = redactedEvent {
            XCTAssertTrue(cmd.contains("API_KEY=[REDACTED]"))
            XCTAssertFalse(cmd.contains("secret_key_12345678"))
        } else {
            XCTFail("Expected commandRun event")
        }
    }
}

final class AntigravityAdapterTests: XCTestCase {
    let adapter = AntigravityAdapter()

    func testPortfolioFixture() throws {
        let fixtureURL = Bundle.module.url(forResource: "session_01_portfolio", withExtension: "jsonl")
            ?? URL(fileURLWithPath: "Tests/ChippyCoreTests/Fixtures/session_01_portfolio.jsonl")

        let content = try String(contentsOf: fixtureURL, encoding: .utf8)
        let lines = content.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        var allEvents: [AgentEvent] = []
        for line in lines {
            let lineData = line.data(using: .utf8)!
            let events = try adapter.events(fromLine: lineData)
            allEvents.append(contentsOf: events)
        }

        // Verify key normalized events
        let hasSessionStarted = allEvents.contains {
            if case .sessionStarted(_, let model, _) = $0 {
                return model == "Gemini 3.8 Flash (High)"
            }
            return false
        }
        XCTAssertTrue(hasSessionStarted, "Expected sessionStarted with model Gemini 3.8 Flash (High)")

        let hasSkillLoaded = allEvents.contains {
            if case .skillLoaded(_, let name) = $0 {
                return name == "frontend-design"
            }
            return false
        }
        XCTAssertTrue(hasSkillLoaded, "Expected skillLoaded frontend-design")

        let hasFileCreated = allEvents.contains {
            if case .fileEdited(_, let path, let kind) = $0 {
                return path.contains("src/App.tsx") && kind == .created
            }
            return false
        }
        XCTAssertTrue(hasFileCreated, "Expected fileEdited created for src/App.tsx")

        let hasCommandRun = allEvents.contains {
            if case .commandRun(_, let cmd) = $0 {
                return cmd == "npm run build"
            }
            return false
        }
        XCTAssertTrue(hasCommandRun, "Expected commandRun npm run build")
    }

    func testSecurityFixture() throws {
        let fixtureURL = Bundle.module.url(forResource: "session_02_security", withExtension: "jsonl")
            ?? URL(fileURLWithPath: "Tests/ChippyCoreTests/Fixtures/session_02_security.jsonl")

        let content = try String(contentsOf: fixtureURL, encoding: .utf8)
        let lines = content.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        var allEvents: [AgentEvent] = []
        for line in lines {
            let lineData = line.data(using: .utf8)!
            let events = try adapter.events(fromLine: lineData)
            allEvents.append(contentsOf: events)
        }

        let hasSecuritySkill = allEvents.contains {
            if case .skillLoaded(_, let name) = $0 {
                return name == "security-hardening"
            }
            return false
        }
        XCTAssertTrue(hasSecuritySkill)

        let hasSearchTool = allEvents.contains {
            if case .toolCall(_, let tool, _) = $0 {
                return tool == .search
            }
            return false
        }
        XCTAssertTrue(hasSearchTool)

        let hasFileModified = allEvents.contains {
            if case .fileEdited(_, _, let kind) = $0 {
                return kind == .modified
            }
            return false
        }
        XCTAssertTrue(hasFileModified)
    }

    func testSubagentFixture() throws {
        let fixtureURL = Bundle.module.url(forResource: "session_03_subagent", withExtension: "jsonl")
            ?? URL(fileURLWithPath: "Tests/ChippyCoreTests/Fixtures/session_03_subagent.jsonl")

        let content = try String(contentsOf: fixtureURL, encoding: .utf8)
        let lines = content.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        var allEvents: [AgentEvent] = []
        for line in lines {
            let lineData = line.data(using: .utf8)!
            let events = try adapter.events(fromLine: lineData)
            allEvents.append(contentsOf: events)
        }

        let hasSubagentSpawn = allEvents.contains {
            if case .subagentSpawned = $0 {
                return true
            }
            return false
        }
        XCTAssertTrue(hasSubagentSpawn)

        let hasAskQuestion = allEvents.contains {
            if case .toolCall(_, let tool, _) = $0 {
                return tool == .ask
            }
            return false
        }
        XCTAssertTrue(hasAskQuestion)
    }

    func testFailsSoftOnUnknownOrMalformedData() throws {
        let emptyEvents = try adapter.events(fromLine: Data())
        XCTAssertEqual(emptyEvents.count, 0)

        let garbageData = "{\"not_valid_json\"".data(using: .utf8)!
        let garbageEvents = try adapter.events(fromLine: garbageData)
        XCTAssertEqual(garbageEvents.count, 0)

        let unknownStep = "{\"step_index\":99,\"source\":\"ALIEN\",\"type\":\"UNKNOWN_GIZMO\",\"status\":\"DONE\"}".data(using: .utf8)!
        let unknownEvents = try adapter.events(fromLine: unknownStep)
        XCTAssertEqual(unknownEvents.count, 0)
    }
}

final class ReplayEngineTests: XCTestCase {
    func testReplayEngineNavigation() async throws {
        let events: [AgentEvent] = [
            .sessionStarted(sessionID: "s1", model: "Gemini", startedAt: Date()),
            .userPrompt(text: "Hello Chippy"),
            .thinking(agentID: "lead"),
            .commandRun(agentID: "lead", command: "swift test")
        ]

        let engine = ReplayEngine(events: events)
        let total = await engine.totalEvents
        XCTAssertEqual(total, 4)

        let first = await engine.stepForward()
        XCTAssertEqual(first, events[0])

        let second = await engine.stepForward()
        XCTAssertEqual(second, events[1])

        let back = await engine.stepBackward()
        XCTAssertEqual(back, events[1])

        let seekResult = await engine.seek(to: 3)
        XCTAssertEqual(seekResult, events[3])

        await engine.setSpeed(.quadruple)
        let speed = await engine.currentSpeed
        XCTAssertEqual(speed, .quadruple)
    }
}

final class IsometricGridTests: XCTestCase {
    let grid = IsometricGrid(tileWidth: 64.0, tileHeight: 32.0)

    func testOriginProjection() {
        let p = grid.gridToScreen(col: 0, row: 0)
        XCTAssertEqual(p.x, 0.0)
        XCTAssertEqual(p.y, 0.0)
    }

    func testCoordinateRoundTrip() {
        let points = [
            GridPoint(col: 0, row: 0),
            GridPoint(col: 5, row: 2),
            GridPoint(col: -3, row: 4),
            GridPoint(col: 10, row: -8)
        ]
        for pt in points {
            let screen = grid.gridToScreen(col: pt.col, row: pt.row)
            let back = grid.screenToGrid(x: screen.x, y: screen.y)
            XCTAssertEqual(back, pt, "Failed roundtrip for point \(pt)")
        }
    }

    func testDepthSorting() {
        // Tile closer to the camera (higher col + row) has lower zPosition
        let z1 = grid.zPosition(col: 1, row: 1)
        let z2 = grid.zPosition(col: 5, row: 5)
        XCTAssertTrue(z1 > z2, "Tiles further back should have higher z-position in SpriteKit standard sorting")
    }
}
