import XCTest
@testable import ChippyCore

final class WorldStateTests: XCTestCase {
    func testDeterministicStateReduction() {
        let initial = WorldState()
        XCTAssertEqual(initial.totalEventsProcessed, 0)

        let events: [AgentEvent] = [
            .sessionStarted(sessionID: "sess-1", model: "gemini-2.5-pro", startedAt: Date()),
            .userPrompt(text: "Build a sleek UI component"),
            .fileRead(agentID: "lead", path: "Sources/Chippy/HUD/ChippyHUDView.swift"),
            .fileEdited(agentID: "lead", path: "Sources/Chippy/HUD/ChippyHUDView.swift", kind: .modified),
            .commandRun(agentID: "lead", command: "swift test")
        ]

        var state = initial
        for event in events {
            state = state.reducing(event)
        }

        XCTAssertEqual(state.totalEventsProcessed, 5)
        XCTAssertEqual(state.activeModel, "gemini-2.5-pro")
        XCTAssertEqual(state.harborCrateFiles["Sources/Chippy/HUD/ChippyHUDView.swift"], 1)

        // Verifying pure determinism: running from initial again produces exact same state
        let recomputed = events.reduce(initial) { $0.reducing($1) }
        XCTAssertEqual(state, recomputed)
    }
}
