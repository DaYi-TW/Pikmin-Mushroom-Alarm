// Target: PikminMushroomAlarm
// Starts / updates / ends a Live Activity per Mushroom.
// One activity per mushroom, identified by mushroom.id.uuidString.

import Foundation
import ActivityKit

@MainActor
struct LiveActivityManager {
    static let shared = LiveActivityManager()

    var areEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    func start(for mushroom: Mushroom) {
        guard areEnabled else { return }

        // If an activity for this mushroom already exists, update instead of starting a duplicate.
        if let existing = activity(for: mushroom.id) {
            Task { await update(existing, with: mushroom) }
            return
        }

        let attributes = MushroomActivityAttributes(
            mushroomID: mushroom.id,
            location: mushroom.location,
            type: mushroom.type
        )
        let state = MushroomActivityAttributes.MushroomState(
            finishDate: mushroom.finishDate,
            respawnDate: mushroom.respawnDate
        )
        let content = ActivityContent(state: state, staleDate: mushroom.respawnDate.addingTimeInterval(60))

        do {
            _ = try Activity.request(attributes: attributes, content: content, pushType: nil)
        } catch {
            // Swallow — user may have disabled Live Activities; not a fatal path.
        }
    }

    func update(for mushroom: Mushroom) async {
        guard let activity = activity(for: mushroom.id) else { return }
        await update(activity, with: mushroom)
    }

    private func update(_ activity: Activity<MushroomActivityAttributes>, with mushroom: Mushroom) async {
        let state = MushroomActivityAttributes.MushroomState(
            finishDate: mushroom.finishDate,
            respawnDate: mushroom.respawnDate
        )
        let content = ActivityContent(state: state, staleDate: mushroom.respawnDate.addingTimeInterval(60))
        await activity.update(content)
    }

    func end(for mushroomID: UUID) async {
        guard let activity = activity(for: mushroomID) else { return }
        await activity.end(activity.content, dismissalPolicy: .immediate)
    }

    func endAll() async {
        for activity in Activity<MushroomActivityAttributes>.activities {
            await activity.end(activity.content, dismissalPolicy: .immediate)
        }
    }

    private func activity(for mushroomID: UUID) -> Activity<MushroomActivityAttributes>? {
        Activity<MushroomActivityAttributes>.activities.first { $0.attributes.mushroomID == mushroomID }
    }
}
