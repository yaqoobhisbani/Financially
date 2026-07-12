import SwiftUI

/// Holds the user's selected color theme and persists it. Injected once at the app root
/// via `.environment(...)`; read anywhere with `@Environment(ThemeManager.self)`.
///
/// The root also applies `.tint(theme.accent)`, so most controls (`.foregroundStyle(.tint)`,
/// glass tints, selection state) follow the theme automatically. Views that fill with the
/// accent directly read `theme.accent` from the environment.
@Observable
final class ThemeManager {
    static let shared = ThemeManager()

    private static let key = "appThemeID"

    var selectedID: String {
        didSet { UserDefaults.standard.set(selectedID, forKey: Self.key) }
    }

    var theme: AppTheme { AppTheme.theme(id: selectedID) }

    private init() {
        selectedID = UserDefaults.standard.string(forKey: Self.key) ?? AppTheme.default.id
    }

    func select(_ theme: AppTheme) {
        selectedID = theme.id
    }
}
