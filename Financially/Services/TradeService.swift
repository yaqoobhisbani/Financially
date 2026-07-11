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
            return (0, 0, 0, 0)
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
            return (0, 0, 0, 0)
        }
        let avgCost = currentCost / Decimal(currentQuantity)
        let newCost = currentCost - (Decimal(soldQuantity) * avgCost)
        let newAvg = newCost / Decimal(remaining)
        return (remaining, newCost, currentFees, newAvg)
    }

    // MARK: - Recalculate Holdings From Trades

    static func recalculateStockHolding(trades: [StockTrade]) -> (totalShares: Int, totalCost: Decimal, totalFeesPaid: Decimal, avgCostPerShare: Decimal) {
        var totalShares = 0
        var totalCost: Decimal = 0
        var totalFeesPaid: Decimal = 0

        for trade in trades.sorted(by: { $0.date < $1.date }) {
            if trade.type == .buy {
                let result = weightedAverageBuyInt(
                    currentQuantity: totalShares,
                    currentCost: totalCost,
                    currentFees: totalFeesPaid,
                    addedQuantity: trade.shares,
                    addedCost: trade.totalAmount,
                    addedFees: trade.brokerageFee + trade.tax
                )
                totalShares = result.quantity
                totalCost = result.cost
                totalFeesPaid = result.fees
            } else {
                let result = weightedAverageSellInt(
                    currentQuantity: totalShares,
                    currentCost: totalCost,
                    currentFees: totalFeesPaid,
                    soldQuantity: trade.shares
                )
                totalShares = result.quantity
                totalCost = result.cost
                totalFeesPaid = result.fees
            }
        }

        let avg = totalShares > 0 ? totalCost / Decimal(totalShares) : 0
        return (totalShares, totalCost, totalFeesPaid, avg)
    }

    static func recalculateCommodityHolding(trades: [CommodityTrade]) -> (totalGrams: Decimal, totalCost: Decimal, totalFeesPaid: Decimal, avgCostPerGram: Decimal) {
        var totalGrams: Decimal = 0
        var totalCost: Decimal = 0
        var totalFeesPaid: Decimal = 0

        for trade in trades.sorted(by: { $0.date < $1.date }) {
            if trade.type == .buy {
                let result = weightedAverageBuy(
                    currentQuantity: totalGrams,
                    currentCost: totalCost,
                    currentFees: totalFeesPaid,
                    addedQuantity: trade.grams,
                    addedCost: trade.totalAmount,
                    addedFees: trade.brokerageFee + trade.tax
                )
                totalGrams = result.quantity
                totalCost = result.cost
                totalFeesPaid = result.fees
            } else {
                let result = weightedAverageSell(
                    currentQuantity: totalGrams,
                    currentCost: totalCost,
                    currentFees: totalFeesPaid,
                    soldQuantity: trade.grams
                )
                totalGrams = result.quantity
                totalCost = result.cost
                totalFeesPaid = result.fees
            }
        }

        let avg = totalGrams > 0 ? totalCost / totalGrams : 0
        return (totalGrams, totalCost, totalFeesPaid, avg)
    }

    static func recalculateMFHolding(trades: [MutualFundTrade]) -> (totalUnits: Decimal, totalCost: Decimal, totalFeesPaid: Decimal, avgNavPrice: Decimal) {
        var totalUnits: Decimal = 0
        var totalCost: Decimal = 0
        var totalFeesPaid: Decimal = 0

        for trade in trades.sorted(by: { $0.date < $1.date }) {
            if trade.type == .buy {
                let result = weightedAverageBuy(
                    currentQuantity: totalUnits,
                    currentCost: totalCost,
                    currentFees: totalFeesPaid,
                    addedQuantity: trade.units,
                    addedCost: trade.totalAmount,
                    addedFees: trade.fees
                )
                totalUnits = result.quantity
                totalCost = result.cost
                totalFeesPaid = result.fees
            } else {
                let result = weightedAverageSell(
                    currentQuantity: totalUnits,
                    currentCost: totalCost,
                    currentFees: totalFeesPaid,
                    soldQuantity: trade.units
                )
                totalUnits = result.quantity
                totalCost = result.cost
                totalFeesPaid = result.fees
            }
        }

        let avg = totalUnits > 0 ? totalCost / totalUnits : 0
        return (totalUnits, totalCost, totalFeesPaid, avg)
    }
}