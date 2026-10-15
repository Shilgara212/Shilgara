import SwiftUI

struct LaunchIntroView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var revealed = false
    @State private var showingIntro = true

    var body: some View {
        ZStack {
            RootView()
                .accessibilityHidden(showingIntro && !reduceMotion)

            if showingIntro && !reduceMotion {
                intro
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .task {
            guard !reduceMotion else {
                showingIntro = false
                return
            }
            withAnimation(.easeOut(duration: 0.72)) { revealed = true }
            try? await Task.sleep(for: .milliseconds(1100))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.32)) { showingIntro = false }
        }
    }

    private var intro: some View {
        ZStack {
            LinearGradient(
                colors: [MSStyle.night, Color(red: 0.18, green: 0.25, blue: 0.43)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            Circle()
                .fill(MSStyle.indigo.opacity(0.25))
                .frame(width: 440, height: 440)
                .blur(radius: 100)
                .offset(x: 170, y: -110)

            VStack(spacing: 0) {
                orbit
                    .frame(width: 220, height: 190)
                    .padding(.bottom, 12)
                Text("Shilgara")
                    .font(.system(size: 42, weight: .semibold, design: .rounded))
                    .tracking(-0.8)
                    .foregroundStyle(.white)
                    .opacity(revealed ? 1 : 0)
                    .offset(y: revealed ? 0 : 12)
                Text("ACADEMIC COMPANION")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(3)
                    .foregroundStyle(.white.opacity(0.63))
                    .padding(.top, 9)
                    .opacity(revealed ? 1 : 0)
                    .offset(y: revealed ? 0 : 8)
                Capsule()
                    .fill(MSStyle.gold)
                    .frame(width: revealed ? 34 : 0, height: 2)
                    .padding(.top, 27)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Opening Shilgara")
    }

    private var orbit: some View {
        ZStack {
            Circle()
                .fill(.white.opacity(0.06))
                .frame(width: 160, height: 160)
                .scaleEffect(revealed ? 1 : 0.82)
            Circle()
                .trim(from: 0, to: revealed ? 1 : 0.01)
                .stroke(.white.opacity(0.22), style: StrokeStyle(lineWidth: 1, lineCap: .round))
                .frame(width: 154, height: 154)
                .rotationEffect(.degrees(-90))
            Ellipse()
                .trim(from: 0, to: revealed ? 1 : 0.01)
                .stroke(.white.opacity(0.79), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: 190, height: 82)
                .rotationEffect(.degrees(revealed ? 34 : 4))
            Ellipse()
                .trim(from: 0, to: revealed ? 1 : 0.01)
                .stroke(.white.opacity(0.37), style: StrokeStyle(lineWidth: 1.3, lineCap: .round))
                .frame(width: 190, height: 82)
                .rotationEffect(.degrees(revealed ? -34 : -4))
            Circle()
                .fill(MSStyle.gold)
                .frame(width: 53, height: 53)
                .shadow(color: MSStyle.gold.opacity(0.42), radius: 26)
                .scaleEffect(revealed ? 1 : 0.42)
                .opacity(revealed ? 1 : 0)
            Circle()
                .fill(.white)
                .frame(width: 8, height: 8)
                .offset(x: 75, y: -49)
                .opacity(revealed ? 1 : 0)
        }
    }
}
