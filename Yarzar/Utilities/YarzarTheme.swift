import Combine
import SwiftUI
import UIKit

enum AppThemeMode: String, CaseIterable, Identifiable {
    case normal = "normal"
    case dark = "dark"

    var id: String { rawValue }

    var colorScheme: ColorScheme {
        switch self {
        case .normal: return .light
        case .dark: return .dark
        }
    }
}

final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published private(set) var currentTheme: AppThemeMode

    private let storageKey = "yarzarThemeMode"

    private init() {
        if let saved = UserDefaults.standard.string(forKey: storageKey),
           let mode = AppThemeMode(rawValue: saved) {
            currentTheme = mode
        } else {
            currentTheme = .dark
        }
    }

    var isDark: Bool {
        currentTheme == .dark
    }

    var colorScheme: ColorScheme {
        currentTheme.colorScheme
    }

    func setTheme(_ mode: AppThemeMode) {
        currentTheme = mode
        UserDefaults.standard.set(mode.rawValue, forKey: storageKey)
    }

    func toggleTheme() {
        setTheme(currentTheme == .dark ? .normal : .dark)
    }
}

enum YarzarTheme {
    static let emerald = Color(red: 0.063, green: 0.725, blue: 0.506)       // #10B981
    static let mintTeal = Color(red: 0.078, green: 0.722, blue: 0.651)      // #14B8A6
    static let limeGood = Color(red: 0.133, green: 0.773, blue: 0.369)      // #22C55E
    static let amberMediocre = Color(red: 0.961, green: 0.620, blue: 0.043) // #F59E0B
    static let crimsonPoor = Color(red: 0.937, green: 0.267, blue: 0.267)   // #EF4444
    static let clinicalCyan = Color(red: 0.024, green: 0.714, blue: 0.831)  // #06B6D4
    static let botanicalPurple = Color(red: 0.545, green: 0.361, blue: 0.965)

    static let brandGradient = LinearGradient(
        colors: [emerald, mintTeal],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func scoreColor(for score: Int) -> Color {
        switch score {
        case 75...100: return emerald
        case 50...74:  return limeGood
        case 20...49:  return amberMediocre
        default:       return crimsonPoor
        }
    }

    static func ratingTitle(for score: Int) -> String {
        switch score {
        case 75...100: return "Excellent"
        case 50...74:  return "Good"
        case 20...49:  return "Mediocre"
        default:       return "Poor"
        }
    }
}

struct YarzarScoreRing: View {
    let score: Int
    var size: CGFloat = 74
    var lineWidth: CGFloat = 8

    private var color: Color {
        YarzarTheme.scoreColor(for: score)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.16), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: CGFloat(max(4, min(100, score))) / 100.0)
                .stroke(
                    AngularGradient(colors: [color.opacity(0.75), color], center: .center),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 0) {
                Text("\(score)")
                    .font(.system(size: size * 0.33, weight: .heavy, design: .rounded))
                    .foregroundStyle(color)
                Text("/100")
                    .font(.system(size: size * 0.14, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
    }
}

struct YarzarCardModifier: ViewModifier {
    var accent: Color = YarzarTheme.emerald

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(accent.opacity(0.25), lineWidth: 1)
            )
    }
}

extension View {
    func yarzarCard(accent: Color = YarzarTheme.emerald) -> some View {
        modifier(YarzarCardModifier(accent: accent))
    }
}
