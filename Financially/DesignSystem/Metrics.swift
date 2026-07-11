import CoreGraphics

/// Concentric corner-radius scale. Nesting an inner shape inside an outer one
/// at these values keeps the borders parallel (Apple's "concentricity" rule).
enum DesignRadius {
    static let outer: CGFloat = 20
    static let inner: CGFloat = 16
    static let control: CGFloat = 12
}

enum DesignSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
}
