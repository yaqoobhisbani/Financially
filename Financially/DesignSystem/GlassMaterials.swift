import SwiftUI

/// Two surfaces, chosen deliberately per view:
///
/// - `.glassChrome()` — floating controls: toolbars, quick-action clusters, floating
///   buttons, sheets. Real Liquid Glass; refracts whatever is beneath it. The system
///   automatically falls back to an opaque surface under Reduce Transparency / Increase
///   Contrast, so no manual fallback is needed here.
/// - `.dataCard()` — content: balances, rows, charts, anything with a currency figure
///   on it. Always opaque — glass behind money hurts legibility.
///
/// Never put a currency figure directly on `.glassChrome()`.

extension View {
    func glassChrome(
        in shape: some Shape = RoundedRectangle(cornerRadius: DesignRadius.outer, style: .continuous),
        tint: Color? = nil,
        interactive: Bool = false
    ) -> some View {
        var glass = Glass.regular
        if let tint {
            glass = glass.tint(tint)
        }
        if interactive {
            glass = glass.interactive()
        }
        return self.glassEffect(glass, in: shape)
    }

    func dataCard(radius: CGFloat = DesignRadius.inner) -> some View {
        modifier(DataCardModifier(radius: radius))
    }
}

private struct DataCardModifier: ViewModifier {
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Color(.separator).opacity(0.5), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.08), radius: 10, y: 3)
    }
}
