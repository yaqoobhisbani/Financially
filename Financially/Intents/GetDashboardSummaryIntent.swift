import Foundation
import AppIntents
import SwiftData

struct GetDashboardSummaryIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Dashboard Summary"
    static var description: LocalizedStringResource = "View your net worth, accounts, and invested amounts"
    static var authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    static var supportedModes: IntentModes = .background

    typealias PerformResult = IntentResultContainer<DashboardSummaryEntity, Never, Never, IntentDialog>

    @MainActor
    func perform() async throws -> PerformResult {
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

        let entity = DashboardSummaryEntity(
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

        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "PKR"
        let nw = f.string(from: netWorth as NSDecimalNumber) ?? "Rs 0"
        let bc = f.string(from: bankCashBalance as NSDecimalNumber) ?? "Rs 0"
        let ti = f.string(from: entity.totalInvested as NSDecimalNumber) ?? "Rs 0"
        let inc = f.string(from: income as NSDecimalNumber) ?? "Rs 0"
        let exp = f.string(from: expense as NSDecimalNumber) ?? "Rs 0"

        return .result(
            value: entity,
            dialog: "Net worth: \(nw). Banks: \(bc). Invested: \(ti). This month: +\(inc) in, -\(exp) out."
        )
    }
}
