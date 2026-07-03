import SwiftUI

extension Color {
    static let incomeGreen = Color.green
    static let expenseRed = Color.red
    static let profitGreen = Color.green
    static let lossRed = Color.red

    static let netWorthAccent = Color.blue
    static let assetsAccent = Color.green
    static let liabilitiesAccent = Color.orange
    static let receivablesAccent = Color.purple

    static let accountBank = Color.blue
    static let accountCash = Color.green
    static let accountPSX = Color.indigo

    static let liquidGlass = Color.white.opacity(0.7)
    static let liquidGlassDark = Color.black.opacity(0.3)
}

extension ShapeStyle where Self == Color {
    static var incomeGreen: Color { .incomeGreen }
    static var expenseRed: Color { .expenseRed }
}