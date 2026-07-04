import Foundation
import SwiftData

struct TradeService {

    // MARK: - Weighted Average Cost (for Decimal quantities e.g. grams)

    static func weightedAverageBuy(
        currentQuantity: Decimal,
        currentCost: Decimal,
        currentFees: Decimal,
        addedQuantity: Decimal,
        addedCost: Decimal,
        addedFees: Decimal
    ) -> (quantity: Decimal, cost: Decimal, fees: Decimal, avgCost: Decimal) {
        let newQuantity = currentQuantity + addedQuantity
        let newCost = currentCost + addedCost
        let newFees = currentFees + addedFees
        let avg = newQuantity > 0 ? newCost / newQuantity : 0
        return (newQuantity, newCost, newFees, avg)
    }

    static func weightedAverageSell(
        currentQuantity: Decimal,
        currentCost: Decimal,
        currentFees: Decimal,
        soldQuantity: Decimal
    ) -> (quantity: Decimal, cost: Decimal, fees: Decimal, avgCost: Decimal) {
        let remaining = currentQuantity - soldQuantity
        if remaining <= 0 {
            return (0, 0, currentFees, 0)
        }
        let avgCost = currentCost / currentQuantity
        let newCost = currentCost - (soldQuantity * avgCost)
        let newAvg = newCost / remaining
        return (remaining, newCost, currentFees, newAvg)
    }

    // MARK: - Weighted Average Cost (for Int quantities e.g. shares)

    static func weightedAverageBuyInt(
        currentQuantity: Int,
        currentCost: Decimal,
        currentFees: Decimal,
        addedQuantity: Int,
        addedCost: Decimal,
        addedFees: Decimal
    ) -> (quantity: Int, cost: Decimal, fees: Decimal, avgCost: Decimal) {
        let newQty = currentQuantity + addedQuantity
        let newCost = currentCost + addedCost
        let newFees = currentFees + addedFees
        let avg = newQty > 0 ? newCost / Decimal(newQty) : 0
        return (newQty, newCost, newFees, avg)
    }

    static func weightedAverageSellInt(
        currentQuantity: Int,
        currentCost: Decimal,
        currentFees: Decimal,
        soldQuantity: Int
    ) -> (quantity: Int, cost: Decimal, fees: Decimal, avgCost: Decimal) {
        let remaining = currentQuantity - soldQuantity
        if remaining <= 0 {
            return (0, 0, currentFees, 0)
        }
        let avgCost = currentCost / Decimal(currentQuantity)
        let newCost = currentCost - (Decimal(soldQuantity) * avgCost)
        let newAvg = newCost / Decimal(remaining)
        return (remaining, newCost, currentFees, newAvg)
    }
}