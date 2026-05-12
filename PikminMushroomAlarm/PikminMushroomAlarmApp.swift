// Target: PikminMushroomAlarm (main app entry)

import SwiftUI
import SwiftData
import ActivityKit
import UserNotifications

@main
struct PikminMushroomAlarmApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var showLaunchScreen = true

    // UNUserNotificationCenter holds its delegate weakly. Without this strong
    // reference on the App struct, NotificationActionHandler.shared could be
    // released after init returns and notification taps would do nothing.
    private let notificationHandler = NotificationActionHandler.shared

    init() {
        UNUserNotificationCenter.current().delegate = notificationHandler
        NotificationScheduler().registerCategories()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                HomeView()
                // Reconcile runs in the splash .task below so we don't double-
                // dispatch on cold launch.

                if showLaunchScreen {
                    LaunchScreenView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .task {
                // Show the splash for at least 0.9s (so the animation has time
                // to land), then run reconcile/permission work in parallel, then
                // fade out. If reconcile takes longer than the minimum, we wait
                // for it before fading rather than yanking the splash early.
                async let minimumDisplay: Void = Task.sleep(nanoseconds: 900_000_000)
                async let warmup: Void = warmupOnFirstAppear()
                _ = try? await minimumDisplay
                _ = await warmup
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

    /// Work that happens once on cold launch, in parallel with the splash's
    /// minimum display window. Keeping it here (not in HomeView.task) means
    /// the splash dismisses only after the home content is ready to show.
    @MainActor
    private func warmupOnFirstAppear() async {
        await reconcileLiveActivities()
    }

    // Share Extension can't start Live Activities (ActivityKit only runs in the
    // foreground app). On launch / foregrounding, sync activities to match the
    // store: start any missing ones, end ones whose mushroom is gone or expired.
    // We also garbage-collect mushrooms that respawned more than an hour ago —
    // they've served their purpose and just clutter the carousel otherwise.
    @MainActor
    private func reconcileLiveActivities() async {
        let context = MushroomStore.shared.mainContext
        let descriptor = FetchDescriptor<Mushroom>()
        guard let mushrooms = try? context.fetch(descriptor) else { return }

        // Cleanup: prune mushrooms that respawned > 1 hour ago. We keep a
        // grace window so a user who opens the app right at respawn still
        // sees a "刷新完成" card before it disappears.
        let pruneCutoff = Date.now.addingTimeInterval(-3600)
        var pruned = false
        for mushroom in mushrooms where mushroom.respawnDate < pruneCutoff {
            context.delete(mushroom)
            pruned = true
        }
        if pruned { try? context.save() }

        let alive = mushrooms.filter { !$0.hasRespawned }
        let aliveIDs = Set(alive.map { $0.id })

        for mushroom in alive {
            await LiveActivityManager.shared.start(for: mushroom)
        }

        for activity in Activity<MushroomActivityAttributes>.activities {
            if !aliveIDs.contains(activity.attributes.mushroomID) {
                await LiveActivityManager.shared.end(for: activity.attributes.mushroomID, immediate: true)
            }
        }
    }
}
