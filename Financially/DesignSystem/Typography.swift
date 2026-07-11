import SwiftUI

/// The type ramp for currency figures. Every size is `.rounded` for the hero amount
/// (net worth) and paired everywhere with tabular digits so columns of numbers don't
/// jitter as they update.
extension Font {
    static let moneyHero = Font.system(size: 34, weight: .bold, design: .rounded)
    static let moneyTitle = Font.title3.weight(.bold)
    static let moneyHeadline = Font.headline.weight(.semibold)
    static let moneyCaption = Font.caption.weight(.medium)
}

extension View {
    /// Locks digit widths so aligned figures (ledgers, statements) don't shift as they update.
    func tabularNumbers() -> some View {
        monospacedDigit()
    }
}
