import SwiftUI

struct LiquidGlassModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(backgroundStyle)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .compositingGroup()
            .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
    }

    private var backgroundStyle: some ShapeStyle {
        colorScheme == .dark
            ? AnyShapeStyle(.ultraThinMaterial)
            : AnyShapeStyle(Color(.secondarySystemGroupedBackground))
    }
}

extension View {
    func liquidGlassBackground() -> some View {
        self.background(Color(.secondarySystemGroupedBackground))
    }

    func liquidGlassCard() -> some View {
        modifier(LiquidGlassModifier())
    }

    func amountText(_ amount: Decimal, currency: String = "PKR") -> some View {
        Text(amount < 0 ? "-\(abs(amount).formattedCurrency(currency: currency))" : amount.formattedCurrency(currency: currency))
    }

    func coloredAmount(_ amount: Decimal, currency: String = "PKR") -> some View {
        Text(amount.formattedCurrency(currency: currency))
            .foregroundStyle(amount >= 0 ? Color.incomeGreen : Color.expenseRed)
    }
}
