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

    /// An icon-only glass button (toolbar "+", gear, ellipsis, trash, cancel "x", …).
    /// Forces a circular border so the pressed/hover highlight follows the circle instead
    /// of the glass button style's default rounded-rectangle. Use for single-glyph buttons;
    /// keep plain `.buttonStyle(.glass)` for text/pill buttons.
    func glassIconButton() -> some View {
        buttonStyle(.glass).buttonBorderShape(.circle)
    }

    func dataCard(radius: CGFloat = DesignRadius.inner) -> some View {
        modifier(DataCardModifier(radius: radius))
    }

    /// A dashboard content card. Opaque `.dataCard()` by default; when the user turns on
    /// "Glass dashboard cards" in Settings, it renders on Liquid Glass — but with an opaque
    /// scrim behind the content so currency figures stay legible (see the "never money on
    /// bare glass" rule above). Falls back to opaque under Reduce Transparency.
    func dashboardCard(radius: CGFloat = DesignRadius.inner) -> some View {
        modifier(DashboardCardModifier(radius: radius))
    }

    /// Fills the whole screen (behind the nav bar too) with the grouped background, so a
    /// screen that puts a custom header — a segmented control, a date-range picker — above
    /// a `List` shares one continuous grouped background instead of a white header strip
    /// over a grey list. Pair with `.scrollContentBackground(.hidden)` on the inner `List`.
    func groupedScreenBackground() -> some View {
        background(Color(.systemGroupedBackground).ignoresSafeArea())
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

/// Switches a dashboard card between the opaque data card and a glass variant based on the
/// user's "Glass dashboard cards" setting (default off).
private struct DashboardCardModifier: ViewModifier {
    let radius: CGFloat

    @AppStorage("dashboardGlassCards") private var glassCards = false
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        if glassCards && !reduceTransparency {
            let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
            content
                // A translucent scrim between the glass and the content keeps currency
                // figures legible while still letting the hero refract through the edges.
                .background(Color(.secondarySystemGroupedBackground).opacity(0.4), in: shape)
                .glassEffect(.regular, in: shape)
                .overlay(shape.strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5))
                .shadow(color: .black.opacity(0.08), radius: 10, y: 3)
        } else {
            content.dataCard(radius: radius)
        }
    }
}
