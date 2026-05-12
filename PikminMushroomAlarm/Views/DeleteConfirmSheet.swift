// Target: PikminMushroomAlarm
// Mirrors DeleteConfirmSheet in pikmin_alarm_mockup.jsx.

import SwiftUI

struct DeleteConfirmSheet: View {
    @Environment(\.dismiss) private var dismiss
    let mushroom: Mushroom
    var onConfirm: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("🗑️")
                .font(.system(size: 36))
                .frame(width: 72, height: 72)
                .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 22))

            Text("刪除這個鬧鐘？")
                .font(.title3.weight(.black))

            Text("\(mushroom.location) 的倒數與後續通知都會被移除。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                Button(role: .destructive) {
                    onConfirm()
                    dismiss()
                } label: {
                    Text("刪除鬧鐘")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 52)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)

                Button { dismiss() } label: {
                    Text("取消")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 52)
                }
                .buttonStyle(.bordered)
                .tint(.secondary)
            }
        }
        .padding(24)
        .padding(.top, 24)
    }
}
