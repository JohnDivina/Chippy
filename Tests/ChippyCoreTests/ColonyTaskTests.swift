import XCTest
@testable import ChippyCore

final class ColonyTaskTests: XCTestCase {
    func testColonyTaskLifecycleFromEvents() {
        let manager = ColonyTaskManager()
        var tasks: [ColonyTask] = []

        // 1. User Prompt creates a Goal task
        tasks = manager.process(event: .userPrompt(text: "Add login feature"), currentTasks: tasks)
        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks[0].category, "Goal")
        XCTAssertEqual(tasks[0].state, .inProgress)
        XCTAssertEqual(tasks[0].assignedFamiliar, .sovereign)

        // 2. File edit creates an Artifact task
        tasks = manager.process(event: .fileEdited(agentID: "main", path: "Sources/Auth/LoginView.swift", kind: .created), currentTasks: tasks)
        XCTAssertEqual(tasks.count, 2)
        XCTAssertTrue(tasks[1].title.contains("Create LoginView.swift"))
        XCTAssertEqual(tasks[1].assignedFamiliar, .weaver)

        // 3. Command run creates a Terminal task
        tasks = manager.process(event: .commandRun(agentID: "main", command: "swift test"), currentTasks: tasks)
        XCTAssertEqual(tasks.count, 3)
        XCTAssertEqual(tasks[2].category, "Terminal")
        XCTAssertEqual(tasks[2].state, .inProgress)
        XCTAssertEqual(tasks[2].assignedFamiliar, .mason)

        // 4. Command finished marks terminal task completed
        tasks = manager.process(event: .commandFinished(agentID: "main", exitCode: 0), currentTasks: tasks)
        XCTAssertEqual(tasks[2].state, .completed)
        XCTAssertNotNil(tasks[2].completedAt)

        // 5. Decision requested creates a Podium task
        tasks = manager.process(event: .decisionRequested(agentID: "main", question: "Should we use OAuth?", options: ["Yes", "No"]), currentTasks: tasks)
        XCTAssertEqual(tasks.count, 4)
        XCTAssertEqual(tasks[3].category, "Podium")
        XCTAssertEqual(tasks[3].assignedFamiliar, .sovereign)

        // 6. Agent message completes the Goal task
        tasks = manager.process(event: .agentMessage(agentID: "main", text: "Login feature implemented successfully."), currentTasks: tasks)
        XCTAssertEqual(tasks[0].state, .completed)
        XCTAssertNotNil(tasks[0].completedAt)
    }

    func testAntigravityAdapterParsesAskQuestionWithOptions() throws {
        let adapter = AntigravityAdapter()
        let jsonLine = """
        {"type":"PLANNER_RESPONSE","tool_calls":[{"name":"ask_question","args":{"question":"Which database?","options":["PostgreSQL","SQLite"]}}]}
        """
        let events = try adapter.events(fromLine: Data(jsonLine.utf8))
        XCTAssertEqual(events.count, 2)

        guard case .decisionRequested(_, let question, let options) = events[0] else {
            XCTFail("Expected .decisionRequested event")
            return
        }

        XCTAssertEqual(question, "Which database?")
        XCTAssertEqual(options, ["PostgreSQL", "SQLite"])
    }
}
