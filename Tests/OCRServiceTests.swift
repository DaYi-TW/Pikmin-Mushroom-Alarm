// Target: PikminMushroomAlarmTests (create this test target in Xcode and add
// this file + OCRService.swift + Mushroom.swift + NotificationOffset.swift to it).
//
// Pure logic tests for OCRService. The Vision-based recognize() path needs a
// real image and on-device OCR, so we cover only the parser layer here —
// parseRemainingSeconds() + parse(lines:) — which is where the brittle
// business logic lives.

import XCTest
@testable import PikminMushroomAlarm

final class OCRServiceTests: XCTestCase {
    private let service = OCRService()

    // MARK: - parseRemainingSeconds

    func test_parseRemainingSeconds_fullForm_withSpaces() {
        XCTAssertEqual(OCRService.parseRemainingSeconds("剩下 1 小時 0 分 13 秒"), 3613)
    }

    func test_parseRemainingSeconds_fullForm_noSpaces() {
        XCTAssertEqual(OCRService.parseRemainingSeconds("剩下1小時0分13秒"), 3613)
    }

    func test_parseRemainingSeconds_subHourForm() {
        XCTAssertEqual(OCRService.parseRemainingSeconds("剩下 12 分 45 秒"), 12 * 60 + 45)
    }

    func test_parseRemainingSeconds_secondsOnly() {
        XCTAssertEqual(OCRService.parseRemainingSeconds("剩下 38 秒"), 38)
    }

    func test_parseRemainingSeconds_returnsNil_forUnrelatedText() {
        XCTAssertNil(OCRService.parseRemainingSeconds("功夫壁畫"))
        XCTAssertNil(OCRService.parseRemainingSeconds("一般 輝煌蘑菇"))
        XCTAssertNil(OCRService.parseRemainingSeconds(""))
    }

    func test_parseRemainingSeconds_pickFullFormFirst_evenIfMinutesSubstringMatches() {
        // The 3-segment line should still parse as hours/minutes/seconds even
        // though the 2-segment pattern would also match the tail.
        XCTAssertEqual(OCRService.parseRemainingSeconds("剩下 2 小時 5 分 9 秒"), 2 * 3600 + 5 * 60 + 9)
    }

    // MARK: - parse(lines:)

    func test_parseLines_usesTopMostNonTimeLineAsLocation() throws {
        let lines = ["功夫壁畫", "一般 輝煌蘑菇", "剩下 1 小時 0 分 13 秒"]
        let result = try service.parse(lines: lines)
        XCTAssertEqual(result.location, "功夫壁畫")
        XCTAssertEqual(result.type, "一般 輝煌蘑菇")
        XCTAssertEqual(result.remainingSeconds, 3613)
    }

    func test_parseLines_throwsWhenNoTimeLine() {
        XCTAssertThrowsError(try service.parse(lines: ["功夫壁畫", "一般 輝煌蘑菇"])) { error in
            guard let ocrError = error as? OCRError else { return XCTFail("wrong error type") }
            XCTAssertEqual(ocrError, .remainingTimeNotFound)
        }
    }

    func test_parseLines_handlesLocationOnlyWhenTypeMissing() throws {
        let lines = ["功夫壁畫", "剩下 12 分 45 秒"]
        let result = try service.parse(lines: lines)
        XCTAssertEqual(result.location, "功夫壁畫")
        XCTAssertEqual(result.type, "")
        XCTAssertEqual(result.remainingSeconds, 12 * 60 + 45)
    }

    // MARK: - finish / respawn derivation

    func test_finishDate_isNowPlusRemainingSeconds() throws {
        let result = try service.parse(lines: ["功夫壁畫", "一般 輝煌蘑菇", "剩下 0 分 30 秒"])
        let delta = result.finishDate.timeIntervalSinceNow
        XCTAssertEqual(delta, 30, accuracy: 1.0)
    }

    func test_respawnDate_isFinishPlusFiveMinutes() throws {
        let result = try service.parse(lines: ["功夫壁畫", "一般 輝煌蘑菇", "剩下 0 分 30 秒"])
        let gap = result.respawnDate.timeIntervalSince(result.finishDate)
        XCTAssertEqual(gap, 300, accuracy: 0.001)
    }
}

extension OCRError: Equatable {
    public static func == (lhs: OCRError, rhs: OCRError) -> Bool {
        switch (lhs, rhs) {
        case (.noTextDetected, .noTextDetected),
             (.remainingTimeNotFound, .remainingTimeNotFound),
             (.imageConversionFailed, .imageConversionFailed):
            return true
        default:
            return false
        }
    }
}
