import XCTest
@testable import ChippyCore

final class LineAssemblerTests: XCTestCase {
    func testLineWrittenInTwoChunks() {
        var assembler = LineAssembler()

        let chunk1 = Data("{\"type\":\"USER_IN".utf8)
        let lines1 = assembler.ingest(chunk1)
        XCTAssertTrue(lines1.isEmpty, "Incomplete line should not be emitted")
        XCTAssertTrue(assembler.hasPendingBytes)

        let chunk2 = Data("PUT\",\"content\":\"hello\"}\n".utf8)
        let lines2 = assembler.ingest(chunk2)
        XCTAssertEqual(lines2.count, 1)
        XCTAssertEqual(lines2.first, "{\"type\":\"USER_INPUT\",\"content\":\"hello\"}")
        XCTAssertFalse(assembler.hasPendingBytes)
    }

    func testThreeLinesInOneChunk() {
        var assembler = LineAssembler()

        let multi = "{\"line\":1}\n{\"line\":2}\n{\"line\":3}\n"
        let lines = assembler.ingest(Data(multi.utf8))
        XCTAssertEqual(lines.count, 3)
        XCTAssertEqual(lines[0], "{\"line\":1}")
        XCTAssertEqual(lines[1], "{\"line\":2}")
        XCTAssertEqual(lines[2], "{\"line\":3}")
        XCTAssertFalse(assembler.hasPendingBytes)
    }

    func testTruncationReset() {
        var assembler = LineAssembler()

        let partial = Data("{\"unfin".utf8)
        _ = assembler.ingest(partial)
        XCTAssertTrue(assembler.hasPendingBytes)

        assembler.reset()
        XCTAssertFalse(assembler.hasPendingBytes)

        let newLine = Data("{\"fresh\":true}\n".utf8)
        let lines = assembler.ingest(newLine)
        XCTAssertEqual(lines.count, 1)
        XCTAssertEqual(lines.first, "{\"fresh\":true}")
    }

    func testLargeOneMegabyteSingleLine() {
        var assembler = LineAssembler()

        let largeContent = String(repeating: "A", count: 1_000_000)
        let json = "{\"data\":\"\(largeContent)\"}\n"
        let data = Data(json.utf8)

        let lines = assembler.ingest(data)
        XCTAssertEqual(lines.count, 1)
        XCTAssertEqual(lines.first?.count, json.count - 1)
        XCTAssertFalse(assembler.hasPendingBytes)
    }
}
