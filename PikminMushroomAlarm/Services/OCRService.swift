// Target: PikminMushroomAlarm + ShareExtension
// Uses Apple Vision Framework for on-device OCR.
// Sample input (zh-TW, from Pikmin Bloom):
//   功夫壁畫
//   一般 輝煌蘑菇
//   剩下 1 小時 0 分 13 秒

import Foundation
import Vision
#if canImport(UIKit)
import UIKit
typealias PlatformImage = UIImage
#endif

struct OCRResult: Sendable, Equatable {
    var location: String
    var type: String
    var remainingSeconds: Int
    var rawLines: [String]

    var finishDate: Date {
        Date.now.addingTimeInterval(TimeInterval(remainingSeconds))
    }

    var respawnDate: Date {
        // Per proposal §4.2 — respawn is 5 minutes after finish.
        finishDate.addingTimeInterval(TimeInterval(NotificationOffset.respawn.rawValue))
    }
}

enum OCRError: Error {
    case noTextDetected
    case remainingTimeNotFound
    case imageConversionFailed
}

struct OCRService {
    func recognize(image: PlatformImage) async throws -> OCRResult {
        guard let cgImage = image.cgImage else { throw OCRError.imageConversionFailed }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        request.recognitionLanguages = ["zh-Hant", "zh-Hans", "en-US"]

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        let observations = request.results ?? []
        let lines = observations.compactMap { $0.topCandidates(1).first?.string }
        guard !lines.isEmpty else { throw OCRError.noTextDetected }

        return try parse(lines: lines)
    }

    // Exposed for unit testing with synthetic OCR lines.
    func parse(lines: [String]) throws -> OCRResult {
        guard let seconds = lines.lazy.compactMap(Self.parseRemainingSeconds).first else {
            throw OCRError.remainingTimeNotFound
        }

        // Heuristic: the line that looks like a type contains "蘑菇"; the
        // remaining non-time, non-type line is the location.
        let nonTimeLines = lines.filter { Self.parseRemainingSeconds($0) == nil }
        let typeLine = nonTimeLines.first(where: { $0.contains("蘑菇") }) ?? ""
        let locationLine = nonTimeLines.first(where: { $0 != typeLine }) ?? ""

        return OCRResult(
            location: locationLine.trimmingCharacters(in: .whitespaces),
            type: typeLine.trimmingCharacters(in: .whitespaces),
            remainingSeconds: seconds,
            rawLines: lines
        )
    }

    /// Parses "剩下 1 小時 0 分 13 秒" and the compact form "剩下1小時0分13秒".
    /// Returns total seconds, or nil if the line doesn't match.
    static func parseRemainingSeconds(_ text: String) -> Int? {
        let pattern = #"剩下\s*(\d+)\s*小時\s*(\d+)\s*分\s*(\d+)\s*秒"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range), match.numberOfRanges == 4 else {
            return nil
        }
        func intAt(_ idx: Int) -> Int? {
            guard let r = Range(match.range(at: idx), in: text) else { return nil }
            return Int(text[r])
        }
        guard let h = intAt(1), let m = intAt(2), let s = intAt(3) else { return nil }
        return h * 3600 + m * 60 + s
    }
}
