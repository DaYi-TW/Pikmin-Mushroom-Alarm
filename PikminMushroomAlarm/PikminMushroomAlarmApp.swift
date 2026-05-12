// Target: PikminMushroomAlarm (main app entry)

import SwiftUI
import SwiftData
import ActivityKit
import UserNotifications

@main
struct PikminMushroomAlarmApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var showLaunchScreen = true

    init() {
        UNUserNotificationCenter.current().delegate = NotificationActionHandler.shared
        NotificationScheduler().registerCategories()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                HomeView()
                    .task { await reconcileLiveActivities() }

                if showLaunchScreen {
                    LaunchScreenView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .task {
                try? await Task.sleep(nanoseconds: 1_100_000_000)
                withAnimation(.easeOut(duration: 0.35)) {
                    showLaunchScreen = false
                }
            }
        }
        .modelContainer(MushroomStore.shared)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await reconcileLiveActivities() }
            }
        }
    }

    // Share Extension can't start Live Activities (ActivityKit only runs in the
    // foreground app). On launch / foregrounding, sync activities to match the
    // store: start any missing ones, end ones whose mushroom is gone or expired.
    @MainActor
    private func reconcileLiveActivities() async {
        let context = MushroomStore.shared.mainContext
        let descriptor = FetchDescriptor<Mushroom>()
        guard let mushrooms = try? context.fetch(descriptor) else { return }
        let alive = mushrooms.filter { !$0.hasRespawned }
        let aliveIDs = Set(alive.map { $0.id })

        for mushroom in alive {
            LiveActivityManager.shared.start(for: mushroom)
        }

        for activity in Activity<MushroomActivityAttributes>.activities {
            if !aliveIDs.contains(activity.attributes.mushroomID) {
                await LiveActivityManager.shared.end(for: activity.attributes.mushroomID)
            }
        }
    }
}
