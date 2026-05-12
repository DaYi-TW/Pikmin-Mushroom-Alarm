// Target: PikminMushroomAlarm
// A small bottom sheet for things that don't belong on the home screen:
//   • notification status check
//   • reset / clear all data
//   • version + build info
//   • links (App Store review placeholder, GitHub)
//
// Keeps the home screen focused on the actual mushroom timers.

import SwiftUI
import SwiftData
import UIKit
import UserNotifications

struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.openURL) private var openURL

    @State private var authStatus: UNAuthorizationStatus = .notDetermined
    @State private var showClearConfirm = false

    private let scheduler = NotificationScheduler()

    var body: some View {
        NavigationStack {
            Form {
                Section("通知") {
                    HStack {
                        Image(systemName: notificationIcon)
                            .foregroundStyle(notificationTint)
                        Text(notificationStatusText)
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        if authStatus != .authorized {
                            Button("前往設定") {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    openURL(url)
                                }
                            }
                            .font(.caption.weight(.bold))
                        }
                    }
                }

                Section("資料") {
                    Button(role: .destructive) {
                        showClearConfirm = true
                    } label: {
                        Label("清除所有蘑菇", systemImage: "trash")
                    }
                }

                Section("關於") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text(versionString)
                            .foregroundStyle(.secondary)
                    }
                    Link(destination: URL(string: "https://github.com/DaYi-TW/Pikmin-Mushroom-Alarm")!) {
                        HStack {
                            Image(systemName: "link")
                            Text("專案原始碼")
                        }
                    }
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .font(.subheadline.weight(.bold))
                }
            }
            .task {
                authStatus = await scheduler.authorizationStatus()
            }
            .confirmationDialog(
                "確定清除所有蘑菇？",
                isPresented: $showClearConfirm,
                titleVisibility: .visible
            ) {
                Button("清除全部", role: .destructive) {
                    Task { await clearAll() }
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("這會刪除所有目前的蘑菇鬧鐘與排程通知，無法復原。")
            }
        }
    }

    private var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }

    private var notificationStatusText: String {
        switch authStatus {
        case .authorized:       return "通知已開啟"
        case .provisional:      return "通知已開啟（試用）"
        case .denied:           return "通知已關閉"
        case .notDetermined:    return "尚未請求通知權限"
        case .ephemeral:        return "通知為臨時權限"
        @unknown default:       return "通知狀態未知"
        }
    }

    private var notificationIcon: String {
        authStatus == .authorized || authStatus == .provisional
            ? "bell.fill" : "bell.slash.fill"
    }

    private var notificationTint: Color {
        authStatus == .authorized || authStatus == .provisional ? .green : .orange
    }

    @MainActor
    private func clearAll() async {
        let descriptor = FetchDescriptor<Mushroom>()
        guard let mushrooms = try? context.fetch(descriptor) else { return }
        for mushroom in mushrooms {
            await scheduler.cancel(for: mushroom)
            await LiveActivityManager.shared.end(for: mushroom.id, immediate: true)
            context.delete(mushroom)
        }
        try? context.save()
        dismiss()
    }
}
