import Foundation

extension Decimal {
    func formattedCurrency(currency: String = "PKR") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: self as NSDecimalNumber) ?? "\(currency) 0.00"
    }

    func formattedWithSign(currency: String = "PKR", isPositive: Bool) -> String {
        let formatted = formattedCurrency(currency: currency)
        return isPositive ? "+\(formatted)" : "-\(formatted)"
    }
}