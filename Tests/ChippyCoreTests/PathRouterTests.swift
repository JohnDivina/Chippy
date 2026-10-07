import XCTest
@testable import ChippyCore

final class PathRouterTests: XCTestCase {
    let router = PathRouter()

    func testRoutesFrontendFilesToWeaver() {
        XCTAssertEqual(router.route(filePath: "src/components/Header.tsx").familiar, .weaver)
        XCTAssertEqual(router.route(filePath: "styles/theme.css").familiar, .weaver)
        XCTAssertEqual(router.route(filePath: "Sources/Chippy/HUD/ChippyHUDView.swift").familiar, .weaver)
    }

    func testRoutesTestFilesToSentinel() {
        XCTAssertEqual(router.route(filePath: "Tests/ChippyCoreTests/RedactorTests.swift").familiar, .sentinel)
        XCTAssertEqual(router.route(filePath: "backend/auth.test.ts").familiar, .sentinel)
    }

    func testRoutesDocsToScribe() {
        XCTAssertEqual(router.route(filePath: "README.md").familiar, .scribe)
        XCTAssertEqual(router.route(filePath: "docs/architecture.markdown").familiar, .scribe)
    }

    func testRoutesBackendFilesToMason() {
        XCTAssertEqual(router.route(filePath: "Sources/ChippyCore/Telemetry/SessionLocator.swift").familiar, .mason)
        XCTAssertEqual(router.route(filePath: "server/db.go").familiar, .mason)
        XCTAssertEqual(router.route(filePath: "scripts/build.sh").familiar, .mason)
    }
}
