#if os(macOS)
import SwiftUI
import EurekaCore

enum Theme {
    static let paper = Color(red: 1.0, green: 0.972, blue: 0.925)
    static let ink = Color(red: 0.13, green: 0.17, blue: 0.27)
    static let violet = Color(red: 0.42, green: 0.27, blue: 0.85)
    static let teal = Color(red: 0.05, green: 0.60, blue: 0.62)
    static let sun = Color(red: 0.98, green: 0.74, blue: 0.13)
    static let coral = Color(red: 0.95, green: 0.42, blue: 0.36)
    static let leaf = Color(red: 0.20, green: 0.66, blue: 0.36)
    static let sky = Color(red: 0.24, green: 0.55, blue: 0.95)
    static let card = Color.white

    static let pairColors: [Color] = [coral, sky, leaf, sun, violet, teal, .pink, .orange, .mint, .indigo, .brown, .cyan]

    static func chapterColor(_ id: ChapterID) -> Color {
        switch id {
        case .pairs: return coral
        case .triangles: return sun
        case .odds: return leaf
        case .doubling: return sky
        case .digits: return violet
        case .pigeons: return teal
        case .grids: return .indigo
        case .logic: return .pink
        }
    }

    static func levelColor(_ level: Level) -> Color {
        switch level {
        case .explorer: return leaf
        case .adventurer: return sky
        case .challenger: return violet
        }
    }

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

struct Pill: View {
    var symbol: String
    var tint: Color
    var text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol).foregroundStyle(tint)
            Text(text).foregroundStyle(Theme.ink)
        }
        .font(Theme.rounded(19))
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(Color.white, in: Capsule())
    }
}

struct BigButton: View {
    var title: String
    var fill: Color
    var ink: Color = .white
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.rounded(22))
                .foregroundStyle(ink)
                .padding(.horizontal, 26)
                .padding(.vertical, 14)
                .frame(minWidth: 120)
                .background(fill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct QuietButton: View {
    var title: String
    var symbol: String?
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let symbol { Image(systemName: symbol) }
                Text(title)
            }
            .font(Theme.rounded(17, .semibold))
            .foregroundStyle(Theme.violet)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Color.white.opacity(0.9), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct StarRow: View {
    var filled: Int
    var size: CGFloat = 18

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { index in
                Image(systemName: index < filled ? "star.fill" : "star")
                    .foregroundStyle(index < filled ? Theme.sun : Theme.ink.opacity(0.25))
            }
        }
        .font(.system(size: size, weight: .bold))
        .accessibilityLabel("\(filled) of 3 stars")
    }
}

struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Theme.ink.opacity(0.08), radius: 8, y: 3)
    }
}

extension View {
    func card() -> some View { modifier(CardBackground()) }
}
#endif
