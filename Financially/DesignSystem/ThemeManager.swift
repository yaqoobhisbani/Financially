import SwiftUI

/// Holds the user's selected color theme and hero pattern — chosen independently, so any
/// color can pair with any pattern — and persists both. Injected once at the app root via
/// `.environment(...)`; read anywhere with `@Environment(ThemeManager.self)`.
///
/// The root also applies `.tint(theme.accent)`, so most controls (`.foregroundStyle(.tint)`,
/// glass tints, selection state) follow the theme automatically. Views that fill with the
/// accent directly read `theme.accent` from the environment.
@Observable
final class ThemeManager {
    static let shared = ThemeManager()

    private static let themeKey = "appThemeID"
    private static let patternKey = "heroPatternID"

    var selectedID: String {
        didSet { UserDefaults.standard.set(selectedID, forKey: Self.themeKey) }
    }

    var selectedPatternID: String {
        didSet { UserDefaults.standard.set(selectedPatternID, forKey: Self.patternKey) }
    }

    var theme: AppTheme { AppTheme.theme(id: selectedID) }
    var pattern: HeroPattern { HeroPattern.pattern(id: selectedPatternID) }

    private init() {
        selectedID = UserDefaults.standard.string(forKey: Self.themeKey) ?? AppTheme.default.id
        selectedPatternID = UserDefaults.standard.string(forKey: Self.patternKey) ?? HeroPattern.default.rawValue
    }

    func select(_ theme: AppTheme) {
        selectedID = theme.id
    }

    func select(_ pattern: HeroPattern) {
        selectedPatternID = pattern.rawValue
    }
}
