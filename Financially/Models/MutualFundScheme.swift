import Foundation
import SwiftData

@Model
final class MutualFundScheme {
    @Attribute(.unique) var id: UUID
    var schemeName: String
    var fundCode: String
    var fundHouse: String?
    var navPrice: Decimal
    var lastUpdatedAt: Date?

    init(
        id: UUID = UUID(),
        schemeName: String,
        fundCode: String,
        fundHouse: String? = nil,
        navPrice: Decimal = 0
    ) {
        self.id = id
        self.schemeName = schemeName
        self.fundCode = fundCode
        self.fundHouse = fundHouse
        self.navPrice = navPrice
    }
}
