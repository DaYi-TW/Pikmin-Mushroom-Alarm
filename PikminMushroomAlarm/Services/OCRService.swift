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

/// One OCR'd line plus where Vision found it on the image. We carry the
/// vertical position so the parser can pick the topmost line as the location
/// regardless of what Chinese characters happened to land in it.
struct OCRLine: Sendable, Equatable {
    var text: String
    /// Vision uses bottom-left origin in normalized coords. We translate to
    /// top-down ordering (smaller = higher on screen) so sort feels natural.
    var topY: CGFloat
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
        let positioned: [OCRLine] = observations.compactMap { obs in
            guard let text = obs.topCandidates(1).first?.string else { return nil }
            // Vision's boundingBox is normalized with origin at bottom-left.
            // Convert to "distance from top" so smaller = higher up.
            let topY = 1 - obs.boundingBox.maxY
            return OCRLine(text: text, topY: topY)
        }
        guard !positioned.isEmpty else { throw OCRError.noTextDetected }

        return try parse(lines: positioned)
    }

    /// Used by the recognize() path with real positional data.
    func parse(lines: [OCRLine]) throws -> OCRResult {
        guard let seconds = lines.lazy.compactMap({ Self.parseRemainingSeconds($0.text) }).first else {
            throw OCRError.remainingTimeNotFound
        }

        // Sort top-to-bottom. In Pikmin Bloom the location name sits above
        // the mushroom type, which sits above the remaining-time line.
        let sorted = lines.sorted { $0.topY < $1.topY }
        let nonTime = sorted.filter { Self.parseRemainingSeconds($0.text) == nil }
        let location = nonTime.first?.text.trimmingCharacters(in: .whitespaces) ?? ""
        let type = nonTime.dropFirst().first?.text.trimmingCharacters(in: .whitespaces) ?? ""

        return OCRResult(
            location: location,
            type: type,
            remainingSeconds: seconds,
            rawLines: sorted.map(\.text)
        )
    }

    /// Convenience overload for unit tests that don't have positional data —
    /// treats array order as top-to-bottom ordering.
    func parse(lines: [String]) throws -> OCRResult {
        let positioned = lines.enumerated().map {
            OCRLine(text: $0.element, topY: CGFloat($0.offset))
        }
        return try parse(lines: positioned)
    }

    /// Parses Pikmin Bloom's "剩下" remaining-time string. Handles:
    ///   • `剩下 1 小時 0 分 13 秒`     (full form, spaces optional)
    ///   • `剩下 12 分 45 秒`          (sub-hour, no 小時 segment)
    ///   • `剩下 38 秒`                (final minute, only seconds)
    /// Returns total seconds, or nil if no variant matches.
    static func parseRemainingSeconds(_ text: String) -> Int? {
        // Order matters — try the most specific pattern first so a "1 小時"
        // doesn't get partially matched by the minutes-only regex.
        let patterns: [(String, (Int?, Int?, Int?) -> Int?)] = [
            (#"剩下\s*(\d+)\s*小時\s*(\d+)\s*分\s*(\d+)\s*秒"#, { h, m, s in
                guard let h, let m, let s else { return nil }
                return h * 3600 + m * 60 + s
            }),
            (#"剩下\s*(\d+)\s*分\s*(\d+)\s*秒"#, { m, s, _ in
                guard let m, let s else { return nil }
                return m * 60 + s
            }),
            (#"剩下\s*(\d+)\s*秒"#, { s, _, _ in
                guard let s else { return nil }
                return s
            })
        ]

        for (pattern, build) in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let range = NSRange(text.startIndex..., in: text)
            guard let match = regex.firstMatch(in: text, range: range) else { continue }
            func intAt(_ idx: Int) -> Int? {
                guard idx < match.numberOfRanges,
                      let r = Range(match.range(at: idx), in: text) else { return nil }
                return Int(text[r])
            }
            let a = intAt(1)
            let b = match.numberOfRanges > 2 ? intAt(2) : nil
            let c = match.numberOfRanges > 3 ? intAt(3) : nil
            if let result = build(a, b, c) { return result }
        }
        return nil
    }
}
