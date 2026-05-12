// Target: PikminMushroomAlarm
// Splash view shown immediately after the system launch screen.
//
// Why both this AND Info.plist's UILaunchScreen?
//   - UILaunchScreen draws the very first frame the user sees while the app
//     is still launching. It can only show a solid color + asset image — no
//     custom views, no gradients, no text. We use `LaunchBackground` color
//     there for a seamless handoff.
//   - This view renders the moment SwiftUI takes over: same background color
//     as the system launch screen (no flash), but adds the gradient, mushroom
//     emoji, and product name. The parent (PikminMushroomAlarmApp) fades it
//     out after ~1.1s.

import SwiftUI

struct LaunchScreenView: View {
    @State private var iconScale: CGFloat = 0.85
    @State private var iconOpacity: Double = 0.0
    @State private var titleOffset: CGFloat = 12
    @State private var titleOpacity: Double = 0.0

    var body: some View {
        ZStack {
            // Same color as Info.plist UILaunchScreen → UIColorName, so the
            // transition from system launch screen to this view is invisible.
            Color("LaunchBackground").ignoresSafeArea()

            // Gradient overlay matching HomeView's background.
            LinearGradient(
                colors: [Color(hex: 0xE7F8D1), Color(hex: 0xD1FAE5), Color(hex: 0xE0F2FE)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .opacity(iconOpacity)

            VStack(spacing: 18) {
                Text("🍄")
                    .font(.system(size: 96))
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)
                    .shadow(color: .green.opacity(0.25), radius: 24, y: 10)

                VStack(spacing: 4) {
                    Text("蘑菇鬧鐘")
                        .font(.system(size: 30, weight: .black))
                    Text("Pikmin Mushroom Alarm")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.green)
                }
                .offset(y: titleOffset)
                .opacity(titleOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.7)) {
                iconScale = 1.0
                iconOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.15)) {
                titleOffset = 0
                titleOpacity = 1.0
            }
        }
    }
}
