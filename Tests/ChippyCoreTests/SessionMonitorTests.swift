import XCTest
@testable import ChippyCore

final class SessionMonitorTests: XCTestCase {
    func testScanSessionsInTemporaryDirectory() async throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        // Create 2 mock session directories
        let session1 = tempDir.appendingPathComponent("session-1")
        let logs1 = session1.appendingPathComponent(".system_generated/logs")
        try FileManager.default.createDirectory(at: logs1, withIntermediateDirectories: true)
        let transcript1 = logs1.appendingPathComponent("transcript.jsonl")
        try "{\"step\":1}\n".write(to: transcript1, atomically: true, encoding: .utf8)

        let session2 = tempDir.appendingPathComponent("session-2")
        let logs2 = session2.appendingPathComponent(".system_generated/logs")
        try FileManager.default.createDirectory(at: logs2, withIntermediateDirectories: true)
        let transcript2 = logs2.appendingPathComponent("transcript.jsonl")
        try "{\"step\":2}\n".write(to: transcript2, atomically: true, encoding: .utf8)

        let monitor = SessionMonitor(baseBrainURL: tempDir)
        let sessions = await monitor.scanSessions()

        XCTAssertEqual(sessions.count, 2)
        XCTAssertTrue(sessions.contains(where: { $0.id == "session-1" }))
        XCTAssertTrue(sessions.contains(where: { $0.id == "session-2" }))
        XCTAssertTrue(sessions.allSatisfy { $0.isActive })
    }
}
