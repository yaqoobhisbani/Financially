import Foundation
import SwiftData

@Model
final class StockInfo {
    @Attribute(.unique) var id: UUID
    var companyName: String
    var ticker: String
    var currentRate: Decimal
    var lastUpdatedAt: Date?

    init(
        id: UUID = UUID(),
        companyName: String,
        ticker: String,
        currentRate: Decimal = 0
    ) {
        self.id = id
        self.companyName = companyName
        self.ticker = ticker
        self.currentRate = currentRate
    }
}