import SwiftUI

/// The full-screen wash behind the dashboard hero: the current theme's gradient with a
/// faint decorative pattern layered on top. The pattern is masked to fade out before it
/// reaches the numbers and is dropped entirely under Reduce Transparency, so it never
/// competes with the currency figures.
struct HeroBackgroundView: View {
    let theme: AppTheme
    let pattern: HeroPattern

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        theme.heroGradient(for: colorScheme)
            .overlay { patternLayer }
            .ignoresSafeArea()
    }

    @ViewBuilder
    private var patternLayer: some View {
        if pattern != .none && !reduceTransparency {
            HeroPatternView(pattern: pattern, tint: theme.foreground(for: colorScheme))
                .opacity(colorScheme == .dark ? 0.12 : 0.09)
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .white, location: 0.0),
                            .init(color: .white, location: 0.28),
                            .init(color: .clear, location: 0.7)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .allowsHitTesting(false)
        }
    }
}

/// Draws a single hero pattern into its bounds. Stateless — all styling (opacity, fade,
/// tint) is applied by the caller. Reused by the theme picker swatches.
struct HeroPatternView: View {
    let pattern: HeroPattern
    let tint: Color

    var body: some View {
        Canvas { context, size in
            let shading = GraphicsContext.Shading.color(tint)
            switch pattern {
            case .none:
                break
            case .dots:
                drawDots(context, size, shading)
            case .diagonalLines:
                drawDiagonalLines(context, size, shading)
            case .waves:
                drawWaves(context, size, shading)
            case .grid:
                drawGrid(context, size, shading)
            case .arcs:
                drawArcs(context, size, shading)
            }
        }
    }

    private func drawDots(_ context: GraphicsContext, _ size: CGSize, _ shading: GraphicsContext.Shading) {
        let spacing: CGFloat = 22
        let radius: CGFloat = 1.7
        var y: CGFloat = spacing / 2
        while y < size.height {
            var x: CGFloat = spacing / 2
            while x < size.width {
                let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                context.fill(Path(ellipseIn: rect), with: shading)
                x += spacing
            }
            y += spacing
        }
    }

    private func drawDiagonalLines(_ context: GraphicsContext, _ size: CGSize, _ shading: GraphicsContext.Shading) {
        let spacing: CGFloat = 20
        var x = -size.height
        while x < size.width {
            var path = Path()
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x + size.height, y: size.height))
            context.stroke(path, with: shading, lineWidth: 1)
            x += spacing
        }
    }

    private func drawWaves(_ context: GraphicsContext, _ size: CGSize, _ shading: GraphicsContext.Shading) {
        let rowHeight: CGFloat = 26
        let amplitude: CGFloat = 6
        let wavelength: CGFloat = 44
        var baseY: CGFloat = rowHeight
        while baseY < size.height + rowHeight {
            var path = Path()
            path.move(to: CGPoint(x: 0, y: baseY))
            var x: CGFloat = 0
            while x <= size.width {
                let y = baseY + amplitude * sin((x / wavelength) * 2 * .pi)
                path.addLine(to: CGPoint(x: x, y: y))
                x += 4
            }
            context.stroke(path, with: shading, lineWidth: 1)
            baseY += rowHeight
        }
    }

    private func drawGrid(_ context: GraphicsContext, _ size: CGSize, _ shading: GraphicsContext.Shading) {
        let spacing: CGFloat = 28
        var x: CGFloat = 0
        while x <= size.width {
            var path = Path()
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
            context.stroke(path, with: shading, lineWidth: 0.75)
            x += spacing
        }
        var y: CGFloat = 0
        while y <= size.height {
            var path = Path()
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            context.stroke(path, with: shading, lineWidth: 0.75)
            y += spacing
        }
    }

    private func drawArcs(_ context: GraphicsContext, _ size: CGSize, _ shading: GraphicsContext.Shading) {
        // Concentric rings radiating from the top-trailing corner, echoing the gradient origin.
        let center = CGPoint(x: size.width, y: 0)
        let spacing: CGFloat = 30
        let maxRadius = hypot(size.width, size.height)
        var radius: CGFloat = spacing
        while radius < maxRadius {
            let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
            context.stroke(Path(ellipseIn: rect), with: shading, lineWidth: 1)
            radius += spacing
        }
    }
}
