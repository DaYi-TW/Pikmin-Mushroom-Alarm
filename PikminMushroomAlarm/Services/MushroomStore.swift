// Target: PikminMushroomAlarm + ShareExtension + PikminWidgets
// SwiftData container backed by the App Group, so the Share Extension,
// the main app, AND the widget see the same mushrooms.
//
// Not @MainActor — the widget runs its timeline provider off the main actor,
// and the Share Extension does its OCR off the main actor too. Callers that
// touch ModelContext on the main thread (like HomeView's @Environment context)
// already get main-actor isolation from SwiftUI, so we don't enforce it here.

import Foundation
import SwiftData

enum MushroomStore {
    static let shared: ModelContainer = {
        let schema = Schema([Mushroom.self])
        let config: ModelConfiguration
        if let url = AppGroup.storeURL {
            config = ModelConfiguration(schema: schema, url: url)
        } else {
            // Fallback for previews / unit tests without the App Group entitlement.
            config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        }
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to build ModelContainer: \(error)")
        }
    }()

    @discardableResult
    static func insert(_ result: OCRResult, into context: ModelContext) -> Mushroom {
        let mushroom = Mushroom(
            location: result.location,
            type: result.type,
            finishDate: result.finishDate,
            respawnDate: result.respawnDate
        )
        context.insert(mushroom)
        try? context.save()
        return mushroom
    }
}
