import XCTest

final class ThemeComplianceTests: XCTestCase {
    func testNoNeonGreenColorsInSources() throws {
        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // ChippyCoreTests
            .deletingLastPathComponent() // Tests
            .deletingLastPathComponent() // Chippy
            .appendingPathComponent("Sources")

        guard FileManager.default.fileExists(atPath: repoRoot.path) else { return }

        let enumerator = FileManager.default.enumerator(at: repoRoot, includingPropertiesForKeys: [.isRegularFileKey])
        var violations: [String] = []

        while let fileURL = enumerator?.nextObject() as? URL {
            guard fileURL.pathExtension == "swift" else { continue }
            guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else { continue }

            if content.contains("Color.green") {
                violations.append("Violation in \(fileURL.lastPathComponent): contains 'Color.green' (forbidden neon)")
            }
            if content.contains("repeatForever") && content.contains("dotPulse") {
                violations.append("Violation in \(fileURL.lastPathComponent): pulsing status dot (forbidden neon/pulsing beacon)")
            }
        }

        XCTAssertTrue(violations.isEmpty, "Theme violations detected:\n" + violations.joined(separator: "\n"))
    }
}
