// Target: PikminMushroomAlarm
// Mirrors HomeScreen + the host frame in pikmin_alarm_mockup.jsx.

import SwiftUI
import SwiftData
import UIKit
import WidgetKit

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Mushroom.createdAt, order: .reverse) private var mushrooms: [Mushroom]

    @State private var activeID: UUID?
    @State private var isAdding = false
    @State private var deleteTarget: Mushroom?
    @State private var editTarget: Mushroom?
    @State private var notificationsDenied = false
    @State private var showSettings = false

    private let scheduler = NotificationScheduler()

    var body: some View {
        ZStack(alignment: .bottom) {
            backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header

                    if notificationsDenied {
                        NotificationsDeniedBanner()
                    }

                    if mushrooms.isEmpty {
                        EmptyStateView { isAdding = true }
                    } else {
                        let selected = selectedMushroom ?? mushrooms[0]
                        HeroCardView(mushroom: selected)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(mushrooms) { mushroom in
                                    MushroomCardView(
                                        mushroom: mushroom,
                                        isActive: mushroom.id == selected.id,
                                        onSelect: { activeID = mushroom.id },
                                        onRequestDelete: { deleteTarget = mushroom },
                                        onRequestEdit: { editTarget = mushroom }
                                    )
                                }
                            }
                            .padding(.horizontal, 4)
                        }

                        carouselDots(selectedID: selected.id)

                        Button { isAdding = true } label: {
                            Label("新增蘑菇鬧鐘", systemImage: "plus")
                                .font(.headline)
                                .frame(maxWidth: .infinity, minHeight: 56)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .controlSize(.large)

                        reminderRows
                    }
                }
                .padding(20)
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $isAdding) {
            AddMushroomSheet { result in
                let mushroom = MushroomStore.insert(result, into: context)
                Task {
                    await scheduler.schedule(for: mushroom)
                    await LiveActivityManager.shared.start(for: mushroom)
                }
                WidgetCenter.shared.reloadAllTimelines()
                activeID = mushroom.id
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $deleteTarget) { mushroom in
            DeleteConfirmSheet(mushroom: mushroom) {
                let mushroomID = mushroom.id
                Task {
                    await scheduler.cancel(for: mushroom)
                    // User-initiated delete → remove the Live Activity right
                    // away rather than letting it linger until respawn.
                    await LiveActivityManager.shared.end(for: mushroomID, immediate: true)
                }
                context.delete(mushroom)
                try? context.save()
                WidgetCenter.shared.reloadAllTimelines()
                if activeID == mushroomID { activeID = nil }
            }
            .presentationDetents([.height(360)])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $editTarget) { mushroom in
            EditMushroomSheet(mushroom: mushroom) {}
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .task {
            _ = try? await scheduler.requestAuthorization()
            let status = await scheduler.authorizationStatus()
            notificationsDenied = (status == .denied)
        }
    }

    private var selectedMushroom: Mushroom? {
        mushrooms.first { $0.id == activeID }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Pikmin Mushroom Alarm")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.green)
                Text(isAdding ? "新增蘑菇" : "蘑菇鬧鐘")
                    .font(.system(size: 28, weight: .black))
            }
            Spacer()
            Button { showSettings = true } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title3.weight(.bold))
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.green)
            }
            .accessibilityLabel("設定")

            if !mushrooms.isEmpty {
                Button { isAdding = true } label: {
                    Image(systemName: "plus")
                        .font(.title2.weight(.heavy))
                        .frame(width: 48, height: 48)
                        .background(Color.green, in: RoundedRectangle(cornerRadius: 16))
                        .foregroundStyle(.white)
                }
                .accessibilityLabel("新增蘑菇鬧鐘")
            }
        }
    }

    private func carouselDots(selectedID: UUID) -> some View {
        HStack(spacing: 6) {
            ForEach(mushrooms) { mushroom in
                Capsule()
                    .fill(mushroom.id == selectedID ? Color.green : Color(.systemGray3))
                    .frame(width: mushroom.id == selectedID ? 28 : 8, height: 8)
                    .animation(.spring, value: selectedID)
                    .onTapGesture { activeID = mushroom.id }
                    .accessibilityLabel("切換到 \(mushroom.location)")
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var reminderRows: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("刷新通知節奏")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("滑動切換蘑菇")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.green)
            }
            // Same slice as the JSX mockup: indices 1..<5 (skip "finished" and "respawn").
            ForEach(Array(NotificationOffset.allCases.dropFirst().dropLast().enumerated()), id: \.element.id) { index, offset in
                ReminderRowView(index: index, offset: offset)
            }
        }
    }

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: 0xE7F8D1), Color(hex: 0xD1FAE5), Color(hex: 0xE0F2FE)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct ReminderRowView: View {
    let index: Int
    let offset: NotificationOffset

    var body: some View {
        HStack(spacing: 12) {
            Text("\(index + 1)")
                .font(.subheadline.weight(.black))
                .frame(width: 36, height: 36)
                .background(Color.green.opacity(0.18), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 2) {
                Text(offset.label)
                    .font(.subheadline.weight(.bold))
                Text("\(offset.offsetLabel) · \(offset.tone)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 16))
    }
}

struct EmptyStateView: View {
    var onOpenAdd: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("🍄")
                .font(.system(size: 56))
                .frame(width: 96, height: 96)
                .background(Color.green.opacity(0.15), in: RoundedRectangle(cornerRadius: 28))
            Text("目前沒有鬧鐘")
                .font(.title.weight(.black))
            Text("新增 Pikmin 截圖後，會自動建立蘑菇倒數與刷新提醒。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(action: onOpenAdd) {
                Label("新增蘑菇鬧鐘", systemImage: "plus")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 56)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .controlSize(.large)
        }
        .padding(32)
        .background(Color.white.opacity(0.9), in: RoundedRectangle(cornerRadius: 28))
    }
}

/// Shown when the user denied notification permission. Without notifications,
/// the entire app is useless — surface it loudly with a Settings deep link.
struct NotificationsDeniedBanner: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "bell.slash.fill")
                    .foregroundStyle(.white)
                Text("通知未開啟")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                Spacer()
            }
            Text("沒有通知權限的話，蘑菇刷新前無法提醒你。")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.95))
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            } label: {
                Text("前往設定開啟")
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white, in: Capsule())
                    .foregroundStyle(.orange)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange, in: RoundedRectangle(cornerRadius: 16))
    }
}

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xff) / 255
        let g = Double((hex >> 8) & 0xff) / 255
        let b = Double(hex & 0xff) / 255
        self.init(red: r, green: g, blue: b)
    }
}
