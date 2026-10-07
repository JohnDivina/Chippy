import XCTest
@testable import ChippyCore

final class NarratorTests: XCTestCase {
    let narrator = Narrator()

    func testNarratesDifferentEventTypes() {
        let fileRead = AgentEvent.fileRead(agentID: "scout", path: "/path/to/ContentView.swift")
        let readCaption = narrator.narrate(event: fileRead)
        XCTAssertTrue(readCaption.contains("ContentView.swift"))
        XCTAssertTrue(readCaption.contains("Scout"))

        let fileEdit = AgentEvent.fileEdited(agentID: "weaver", path: "App.tsx", kind: .modified)
        let editCaption = narrator.narrate(event: fileEdit)
        XCTAssertTrue(editCaption.contains("Weaver"))
        XCTAssertTrue(editCaption.contains("App.tsx"))

        let quotaError = AgentEvent.error(agentID: "lead", message: "Resource exhausted", reason: .quotaExceeded)
        let errorCaption = narrator.narrate(event: quotaError)
        XCTAssertTrue(errorCaption.contains("quota"))
    }
}
