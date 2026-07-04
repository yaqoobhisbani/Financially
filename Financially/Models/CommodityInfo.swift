import Foundation
import SwiftData

@Model
final class CommodityInfo {
    @Attribute(.unique) var id: UUID
    var name: String
    var symbol: String
    var currentRatePerGram: Decimal

    init(
        id: UUID = UUID(),
        name: String,
        symbol: String,
        currentRatePerGram: Decimal = 0
    ) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.currentRatePerGram = currentRatePerGram
    }
}
