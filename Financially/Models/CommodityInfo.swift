import Foundation
import SwiftData

@Model
final class CommodityInfo {
    @Attribute(.unique) var id: UUID
    var name: String
    var currentRatePerGram: Decimal

    init(
        id: UUID = UUID(),
        name: String,
        currentRatePerGram: Decimal = 0
    ) {
        self.id = id
        self.name = name
        self.currentRatePerGram = currentRatePerGram
    }
}
