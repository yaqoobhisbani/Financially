import Testing
import Foundation
@testable import Financially

@Suite("Decimal+Currency")
struct DecimalCurrencyTests {

    @Test func formattedCurrencyIncludesTwoDecimalPlaces() {
        let value: Decimal = 1234.5
        let formatted = value.formattedCurrency(currency: "PKR")
        #expect(formatted.contains("1,234.50") || formatted.contains("1234.50"))
    }

    @Test func formattedCurrencyHandlesZero() {
        let formatted = Decimal(0).formattedCurrency()
        #expect(formatted.contains("0.00"))
    }

    @Test func formattedCurrencyHandlesNegativeValues() {
        let formatted = Decimal(-500).formattedCurrency()
        #expect(formatted.contains("500.00"))
        #expect(formatted.contains("-") || formatted.contains("("))
    }

    @Test func formattedNumberUsesUpToFourFractionDigits() {
        let value: Decimal = 12.3456789
        let formatted = value.formattedNumber()
        #expect(!formatted.contains("3456789"))
    }

    @Test func formattedNAVPriceAlwaysShowsFourDecimals() {
        let formatted = Decimal(10).formattedNAVPrice()
        #expect(formatted == "10.0000")
    }

    @Test func formattedNAVPriceRoundTripsFractionalValue() {
        let formatted = Decimal(123.4567).formattedNAVPrice()
        #expect(formatted == "123.4567")
    }
}
