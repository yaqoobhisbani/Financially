import SwiftUI

/// `Color.gain` and `Color.loss` are generated automatically from the asset catalog
/// (Gain.colorset / Loss.colorset) — profit, income, and credit use `.gain`; loss,
/// expense, and debit use `.loss`. Nothing else should use them.

extension Color {
    /// The single brand tint, sourced from the AccentColor asset (cobalt).
    /// Use for any control that should read as "the app's color" — CTAs, selection state, links.
    static let brandTint = Color.accentColor
}
