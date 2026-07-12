import SwiftUI

/// A predefined, handpicked color theme. Each bundles an accent tint with a matching
/// dashboard hero gradient and a foreground color proven to stay legible on it, so contrast
/// is guaranteed by design. The decorative hero pattern is chosen independently (see
/// `HeroPattern`), so any color can pair with any pattern. Users pick from `AppTheme.all`.
struct AppTheme: Identifiable, Equatable {
    let id: String
    let name: String

    /// Accent tint applied app-wide (light/dark aware). Drives `.tint(...)` at the root.
    let accent: Color

    /// Top color of the dashboard hero wash, per appearance. The wash fades to clear below.
    private let heroTopLight: Color
    private let heroTopDark: Color

    /// Text / icon color for content sitting on the hero, per appearance.
    private let foregroundLight: Color
    private let foregroundDark: Color

    // MARK: - Resolved values

    /// The full-screen hero wash: top-right → bottom-left, fading to clear so the grouped
    /// background shows through the lower portion of the dashboard.
    func heroGradient(for scheme: ColorScheme) -> LinearGradient {
        let top = scheme == .dark ? heroTopDark : heroTopLight
        return LinearGradient(
            stops: [
                .init(color: top, location: 0.0),
                .init(color: top.opacity(0.9), location: 0.46),
                .init(color: top.opacity(0.0), location: 0.74)
            ],
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
    }

    /// Text / icon color for content sitting on the hero gradient.
    func foreground(for scheme: ColorScheme) -> Color {
        scheme == .dark ? foregroundDark : foregroundLight
    }

    /// A solid, non-fading gradient for theme-picker chips (accent → light hero tint).
    var swatchGradient: LinearGradient {
        LinearGradient(
            colors: [accent, heroTopLight],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Palette

extension AppTheme {
    /// The default theme, matching the app's original cobalt look.
    static let cobalt = AppTheme(
        id: "cobalt",
        name: "Cobalt",
        accent: Color(light: 0x3B5BFF, dark: 0x6E8BFF),
        heroTopLight: Color(hex: 0xA9CCFA),
        heroTopDark: Color(hex: 0x3B5BFF),
        foregroundLight: Color(hex: 0x142150),
        foregroundDark: .white
    )

    static let emerald = AppTheme(
        id: "emerald",
        name: "Emerald",
        accent: Color(light: 0x059669, dark: 0x34D399),
        heroTopLight: Color(hex: 0xA7E8CE),
        heroTopDark: Color(hex: 0x047857),
        foregroundLight: Color(hex: 0x053D2C),
        foregroundDark: .white
    )

    static let violet = AppTheme(
        id: "violet",
        name: "Violet",
        accent: Color(light: 0x7C3AED, dark: 0xA78BFA),
        heroTopLight: Color(hex: 0xD6C6FA),
        heroTopDark: Color(hex: 0x6D28D9),
        foregroundLight: Color(hex: 0x2B0F5B),
        foregroundDark: .white
    )

    static let sunset = AppTheme(
        id: "sunset",
        name: "Sunset",
        accent: Color(light: 0xEA580C, dark: 0xFB923C),
        heroTopLight: Color(hex: 0xFBD5A5),
        heroTopDark: Color(hex: 0xC2410C),
        foregroundLight: Color(hex: 0x5A2408),
        foregroundDark: .white
    )

    static let teal = AppTheme(
        id: "teal",
        name: "Teal",
        accent: Color(light: 0x0D9488, dark: 0x2DD4BF),
        heroTopLight: Color(hex: 0xA5E4DD),
        heroTopDark: Color(hex: 0x0F766E),
        foregroundLight: Color(hex: 0x053C38),
        foregroundDark: .white
    )

    static let rose = AppTheme(
        id: "rose",
        name: "Rose",
        accent: Color(light: 0xDB2777, dark: 0xF472B6),
        heroTopLight: Color(hex: 0xF7C1DA),
        heroTopDark: Color(hex: 0xBE185D),
        foregroundLight: Color(hex: 0x5A0C33),
        foregroundDark: .white
    )

    static let graphite = AppTheme(
        id: "graphite",
        name: "Graphite",
        accent: Color(light: 0x475569, dark: 0x94A3B8),
        heroTopLight: Color(hex: 0xCBD5E1),
        heroTopDark: Color(hex: 0x334155),
        foregroundLight: Color(hex: 0x1E293B),
        foregroundDark: .white
    )

    /// Every selectable theme, in display order. `first` is the default.
    static let all: [AppTheme] = [.cobalt, .emerald, .violet, .sunset, .teal, .rose, .graphite]

    static let `default`: AppTheme = .cobalt

    /// Resolves a stored id back to a theme, falling back to the default if unknown.
    static func theme(id: String) -> AppTheme {
        all.first { $0.id == id } ?? .default
    }
}

// MARK: - Hero pattern

/// A decorative motif drawn faintly over the dashboard hero gradient. Chosen independently
/// of the color theme, so any pattern pairs with any color. Kept subtle and masked to fade
/// out before it reaches the numbers, so it reads as texture, not clutter.
enum HeroPattern: String, CaseIterable, Identifiable {
    case none, dots, diagonalLines, waves, grid, arcs

    var id: String { rawValue }

    /// The default pattern, matching the app's original cobalt look.
    static let `default`: HeroPattern = .dots

    var name: String {
        switch self {
        case .none: return "None"
        case .dots: return "Dots"
        case .diagonalLines: return "Lines"
        case .waves: return "Waves"
        case .grid: return "Grid"
        case .arcs: return "Arcs"
        }
    }

    /// Resolves a stored raw value back to a pattern, falling back to the default.
    static func pattern(id: String) -> HeroPattern {
        HeroPattern(rawValue: id) ?? .default
    }
}

// MARK: - Color helpers

extension Color {
    /// A hex literal like `0x3B5BFF` in sRGB.
    init(hex: UInt) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }

    /// A dynamic color that resolves to `light` in light mode and `dark` in dark mode.
    init(light: UInt, dark: UInt) {
        self = Color(UIColor { traits in
            UIColor(Color(hex: traits.userInterfaceStyle == .dark ? dark : light))
        })
    }
}
