import SwiftUI

enum MSStyle {
    static let indigo = Color(red: 0.36, green: 0.34, blue: 0.73)
    static let teal = Color(red: 0.13, green: 0.52, blue: 0.50)
    static let coral = Color(red: 0.79, green: 0.42, blue: 0.32)
    static let gold = Color(red: 0.86, green: 0.63, blue: 0.33)
    static let night = Color(red: 0.10, green: 0.14, blue: 0.24)
    static let accentText = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: 0.69, green: 0.67, blue: 0.99, alpha: 1)
            : NSColor(red: 0.31, green: 0.29, blue: 0.65, alpha: 1)
    })
    static let tealText = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: 0.51, green: 0.82, blue: 0.78, alpha: 1)
            : NSColor(red: 0.10, green: 0.43, blue: 0.41, alpha: 1)
    })
    static let ink = Color.primary
    static let muted = Color.secondary
    static let canvas = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: 0.075, green: 0.095, blue: 0.145, alpha: 1)
            : NSColor(red: 0.966, green: 0.954, blue: 0.931, alpha: 1)
    })
    static let surface = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: 0.125, green: 0.150, blue: 0.214, alpha: 1)
            : NSColor(red: 0.999, green: 0.993, blue: 0.978, alpha: 1)
    })
    static let soft = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: 0.18, green: 0.205, blue: 0.27, alpha: 1)
            : NSColor(red: 0.931, green: 0.909, blue: 0.877, alpha: 1)
    })
}

struct SurfaceCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MSStyle.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(.primary.opacity(0.065)))
            .shadow(color: MSStyle.night.opacity(0.055), radius: 22, y: 9)
    }
}

struct SectionHeading: View {
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.system(size: 33, weight: .semibold, design: .rounded))
            Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct Pill: View {
    @Environment(\.colorScheme) private var colorScheme
    let text: String
    var color: Color = MSStyle.indigo
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .tracking(0.7)
            .padding(.horizontal, 10).padding(.vertical, 6)
            .foregroundStyle(colorScheme == .dark ? .white.opacity(0.89) : color)
            .background(color.opacity(colorScheme == .dark ? 0.22 : 0.11), in: Capsule())
    }
}

struct EmptyMessage: View {
    let symbol: String
    let title: String
    let message: String
    var body: some View {
        VStack(spacing: 11) {
            Image(systemName: symbol).font(.system(size: 29, weight: .light)).foregroundStyle(MSStyle.indigo)
                .frame(width: 72, height: 72).background(MSStyle.soft, in: Circle())
            Text(title).font(.headline)
            Text(message).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 42)
    }
}

struct BrandMark: View {
    var color: Color = .white
    var body: some View {
        ZStack {
            Ellipse().stroke(color.opacity(0.8), lineWidth: 2.3)
                .frame(width: 30, height: 18).rotationEffect(.degrees(38))
            Ellipse().stroke(color.opacity(0.8), lineWidth: 2.3)
                .frame(width: 30, height: 18).rotationEffect(.degrees(-38))
            Circle().fill(color).frame(width: 6, height: 6)
        }
        .frame(width: 42, height: 42)
        .accessibilityLabel("Shilgara mark")
    }
}

struct OrbitArtwork: View {
    var body: some View {
        ZStack {
            Circle().fill(.white.opacity(0.07)).frame(width: 270, height: 270)
            Circle().stroke(.white.opacity(0.26), lineWidth: 1).frame(width: 239, height: 239)
            Ellipse().stroke(.white.opacity(0.52), lineWidth: 2)
                .frame(width: 285, height: 127).rotationEffect(.degrees(34))
            Ellipse().stroke(.white.opacity(0.24), lineWidth: 1)
                .frame(width: 283, height: 127).rotationEffect(.degrees(-34))
            Circle().fill(MSStyle.gold).frame(width: 88, height: 88)
                .shadow(color: MSStyle.gold.opacity(0.35), radius: 25)
            Circle().fill(.white).frame(width: 13, height: 13).offset(x: 118, y: -76)
            Circle().fill(MSStyle.gold).frame(width: 8, height: 8).offset(x: -113, y: 74)
        }
        .frame(width: 300, height: 280)
        .accessibilityHidden(true)
    }
}

extension Double {
    var percentText: String { formatted(.number.precision(.fractionLength(0...1))) + "%" }
}
