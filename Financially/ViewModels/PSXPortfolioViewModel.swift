import Foundation
import SwiftData

@Observable
final class PSXPortfolioViewModel {
    private let modelContext: ModelContext
    let account: Account

    private var allLedgerEntries: [LedgerEntry] { (try? modelContext.fetch(FetchDescriptor<LedgerEntry>())) ?? [] }
    private var allTransactions: [Transaction] { (try? modelContext.fetch(FetchDescriptor<Transaction>())) ?? [] }
    private var allHoldings: [StockHolding] { (try? modelContext.fetch(FetchDescriptor<StockHolding>())) ?? [] }

    init(modelContext: ModelContext, account: Account) {
        self.modelContext = modelContext
        self.account = account
    }

    var ledgerEntries: [LedgerEntry] {
        allLedgerEntries.filter { $0.accountId == account.id }
            .sorted { $0.date > $1.date }
    }

    var accountHoldings: [StockHolding] {
        allHoldings.filter { $0.accountId == account.id && $0.totalShares > 0 }
    }

    var totalHoldingValue: Decimal {
        accountHoldings.reduce(0) { $0 + $1.currentValue }
    }

    var totalCostBasis: Decimal {
        accountHoldings.reduce(0) { $0 + $1.totalCost }
    }

    var totalUnrealizedPAndL: Decimal {
        accountHoldings.reduce(0) { $0 + $1.unrealizedPAndL }
    }

    var totalPAndLPercentage: Decimal {
        guard totalCostBasis > 0 else { return 0 }
        return (totalUnrealizedPAndL / totalCostBasis) * 100
    }

    func transaction(for entry: LedgerEntry) -> Transaction? {
        allTransactions.first { $0.id == entry.transactionId }
    }

    func toggleActive() {
        account.isActive.toggle()
        account.updatedAt = Date()
    }
}