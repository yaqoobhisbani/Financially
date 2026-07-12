import SwiftUI

/// A tiny inline trend line for summary cards — a single stroked path with a soft
/// gradient fill beneath it. Purely decorative context for the headline figure.
struct SparklineView: View {
    let values: [Decimal]
    let tint: Color

    private var points: [CGFloat] {
        values.map { CGFloat(truncating: $0 as NSNumber) }
    }

    var body: some View {
        GeometryReader { geo in
            let pts = points
            if pts.count >= 2 {
                let maxV = pts.max() ?? 1
                let minV = pts.min() ?? 0
                let range = max(maxV - minV, 1)
                let stepX = geo.size.width / CGFloat(pts.count - 1)

                let coords: [CGPoint] = pts.enumerated().map { index, value in
                    let x = CGFloat(index) * stepX
                    let y = geo.size.height * (1 - (value - minV) / range)
                    return CGPoint(x: x, y: y)
                }

                ZStack {
                    fillPath(coords, in: geo.size)
                        .fill(
                            LinearGradient(
                                colors: [tint.opacity(0.22), tint.opacity(0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    linePath(coords)
                        .stroke(tint, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                }
            }
        }
        .frame(height: 28)
        .accessibilityHidden(true)
    }

    private func linePath(_ coords: [CGPoint]) -> Path {
        var path = Path()
        guard let first = coords.first else { return path }
        path.move(to: first)
        coords.dropFirst().forEach { path.addLine(to: $0) }
        return path
    }

    private func fillPath(_ coords: [CGPoint], in size: CGSize) -> Path {
        var path = linePath(coords)
        guard let last = coords.last, let first = coords.first else { return path }
        path.addLine(to: CGPoint(x: last.x, y: size.height))
        path.addLine(to: CGPoint(x: first.x, y: size.height))
        path.closeSubpath()
        return path
    }
}
