import SwiftUI

extension Color {
    static let incomeGreen = Color.gain
    static let expenseRed = Color.loss

    static let netWorthAccent = Color.brandTint
    static let assetsAccent = Color.gain
    static let liabilitiesAccent = Color.orange
    static let receivablesAccent = Color.purple

    static let accountBank = Color.brandTint
    static let accountCash = Color.gain
    static let accountPSX = Color.indigo
}

extension ShapeStyle where Self == Color {
    static var incomeGreen: Color { .incomeGreen }
    static var expenseRed: Color { .expenseRed }
}