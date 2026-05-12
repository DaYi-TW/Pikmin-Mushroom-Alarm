// Target: PikminMushroomAlarm
// Starts / updates / ends a Live Activity per Mushroom.
// One activity per mushroom, identified by mushroom.id.

import Foundation
import ActivityKit

@MainActor
struct LiveActivityManager {
    static let shared = LiveActivityManager()

    var areEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    /// Starts a Live Activity for `mushroom`, or updates the existing one if
    /// already running. Awaiting the call guarantees the activity is observable
    /// (e.g. by `Activity.activities`) before control returns to the caller.
    func start(for mushroom: Mushroom) async {
        guard areEnabled else { return }

        // If an activity for this mushroom already exists, update instead of starting a duplicate.
        if let existing = activity(for: mushroom.id) {
            await update(existing, with: mushroom)
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

    /// Ends the activity for `mushroomID`. By default, schedules the activity
    /// to auto-dismiss 60 s after respawn so the user can still glance at the
    /// "刷新完成" state on the Lock Screen / Dynamic Island for a minute.
    /// Pass `immediate: true` from the delete flow to remove it right away.
    func end(for mushroomID: UUID, immediate: Bool = false) async {
        guard let activity = activity(for: mushroomID) else { return }
        let policy: ActivityUIDismissalPolicy
        if immediate {
            policy = .immediate
        } else {
            let dismissAt = activity.content.state.respawnDate.addingTimeInterval(60)
            policy = .after(dismissAt)
        }
        await activity.end(activity.content, dismissalPolicy: policy)
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
