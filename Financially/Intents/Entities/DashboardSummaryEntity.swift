import Foundation
import AppIntents
import SwiftData

struct DashboardSummaryEntity: AppEntity {
    let id: UUID
    let netWorth: Decimal
    let totalAssets: Decimal
    let totalLiabilities: Decimal
    let bankCashBalance: Decimal
    let psxInvested: Decimal
    let mfInvested: Decimal
    let commodityInvested: Decimal
    let monthlyIncome: Decimal
    let monthlyExpense: Decimal

    var totalInvested: Decimal {
        psxInvested + mfInvested + commodityInvested
    }

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Dashboard Summary"

    var displayRepresentation: DisplayRepresentation {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.currencyCode = "PKR"
        let nw = nf.string(from: netWorth as NSDecimalNumber) ?? "Rs 0"
        let bc = nf.string(from: bankCashBalance as NSDecimalNumber) ?? "Rs 0"
        let ti = nf.string(from: totalInvested as NSDecimalNumber) ?? "Rs 0"
        let li = nf.string(from: totalLiabilities as NSDecimalNumber) ?? "Rs 0"
        return DisplayRepresentation(
            title: "Net Worth: \(nw)",
            subtitle: "Banks: \(bc)  Invested: \(ti)  Liabilities: \(li)",
            image: DisplayRepresentation.Image(systemName: "chart.pie.fill")
        )
    }

    static var defaultQuery = DashboardSummaryQuery()
}

struct DashboardSummaryQuery: EntityQuery {
    @MainActor
    func entities(for ids: [DashboardSummaryEntity.ID]) async throws -> [DashboardSummaryEntity] {
        let snapshot = makeSnapshot()
        return ids.map { id in
            DashboardSummaryEntity(
                id: id,
                netWorth: snapshot.netWorth,
                totalAssets: snapshot.totalAssets,
                totalLiabilities: snapshot.totalLiabilities,
                bankCashBalance: snapshot.bankCashBalance,
                psxInvested: snapshot.psxInvested,
                mfInvested: snapshot.mfInvested,
                commodityInvested: snapshot.commodityInvested,
                monthlyIncome: snapshot.monthlyIncome,
                monthlyExpense: snapshot.monthlyExpense
            )
        }
    }

    @MainActor
    func suggestedEntities() async throws -> [DashboardSummaryEntity] {
        return [makeSnapshot()]
    }

    @MainActor
    private func makeSnapshot() -> DashboardSummaryEntity {
        let context = ModelContainer.financially.mainContext
        let accounts = (try? context.fetch(FetchDescriptor<Account>())) ?? []
        let debtors = (try? context.fetch(FetchDescriptor<Debtor>())) ?? []
        let creditors = (try? context.fetch(FetchDescriptor<Creditor>())) ?? []
        let transactions = (try? context.fetch(FetchDescriptor<Transaction>())) ?? []
        let stockHoldings = (try? context.fetch(FetchDescriptor<StockHolding>())) ?? []
        let mfHoldings = (try? context.fetch(FetchDescriptor<MutualFundHolding>())) ?? []
        let commodityHoldings = (try? context.fetch(FetchDescriptor<CommodityHolding>())) ?? []

        let totalAssets = accounts.reduce(0 as Decimal) { $0 + $1.currentValue }
        let totalLiabilities = debtors.reduce(0 as Decimal) { $0 + $1.outstandingBalance }
            + creditors.reduce(0 as Decimal) { $0 + $1.outstandingBalance }
        let netWorth = totalAssets - totalLiabilities
        let bankCashBalance = accounts.filter { $0.accountType == .bank || $0.accountType == .cash }
            .reduce(0 as Decimal) { $0 + $1.currentBalance }
        let psxInvested = stockHoldings.reduce(0 as Decimal) { $0 + $1.totalCost }
        let mfInvested = mfHoldings.reduce(0 as Decimal) { $0 + $1.totalCost }
        let commodityInvested = commodityHoldings.reduce(0 as Decimal) { $0 + $1.totalCost }

        let calendar = Calendar.current
        let now = Date()
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        let monthTxs = transactions.filter { $0.date >= monthStart }
        let income = monthTxs.filter { $0.type == .income || $0.type == .committeePayout }
            .reduce(0 as Decimal) { $0 + $1.amount }
        let expense = monthTxs.filter { $0.type == .expense || $0.type == .committeeContribution }
            .reduce(0 as Decimal) { $0 + $1.amount }

        return DashboardSummaryEntity(
            id: UUID(),
            netWorth: netWorth,
            totalAssets: totalAssets,
            totalLiabilities: totalLiabilities,
            bankCashBalance: bankCashBalance,
            psxInvested: psxInvested,
            mfInvested: mfInvested,
            commodityInvested: commodityInvested,
            monthlyIncome: income,
            monthlyExpense: expense
        )
    }
}
