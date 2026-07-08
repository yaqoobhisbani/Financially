import Foundation
import SwiftData

// MARK: - Backup Codable Models

struct BackupData: Codable {
    let version: Int
    let exportedAt: Date
    var accounts: [BackupAccount]
    var categories: [BackupCategory]
    var committees: [BackupCommittee]
    var committeeContributions: [BackupCommitteeContribution]
    var committeePayouts: [BackupCommitteePayout]
    var commodityHoldings: [BackupCommodityHolding]
    var commodityInfos: [BackupCommodityInfo]
    var commodityTrades: [BackupCommodityTrade]
    var creditors: [BackupCreditor]
    var debtors: [BackupDebtor]
    var investmentEntries: [BackupInvestmentEntry]
    var ledgerEntries: [BackupLedgerEntry]
    var stockHoldings: [BackupStockHolding]
    var stockInfos: [BackupStockInfo]
    var stockTrades: [BackupStockTrade]
    var transactions: [BackupTransaction]

    init(
        accounts: [BackupAccount] = [],
        categories: [BackupCategory] = [],
        committees: [BackupCommittee] = [],
        committeeContributions: [BackupCommitteeContribution] = [],
        committeePayouts: [BackupCommitteePayout] = [],
        commodityHoldings: [BackupCommodityHolding] = [],
        commodityInfos: [BackupCommodityInfo] = [],
        commodityTrades: [BackupCommodityTrade] = [],
        creditors: [BackupCreditor] = [],
        debtors: [BackupDebtor] = [],
        investmentEntries: [BackupInvestmentEntry] = [],
        ledgerEntries: [BackupLedgerEntry] = [],
        stockHoldings: [BackupStockHolding] = [],
        stockInfos: [BackupStockInfo] = [],
        stockTrades: [BackupStockTrade] = [],
        transactions: [BackupTransaction] = []
    ) {
        self.version = 1
        self.exportedAt = Date()
        self.accounts = accounts
        self.categories = categories
        self.committees = committees
        self.committeeContributions = committeeContributions
        self.committeePayouts = committeePayouts
        self.commodityHoldings = commodityHoldings
        self.commodityInfos = commodityInfos
        self.commodityTrades = commodityTrades
        self.creditors = creditors
        self.debtors = debtors
        self.investmentEntries = investmentEntries
        self.ledgerEntries = ledgerEntries
        self.stockHoldings = stockHoldings
        self.stockInfos = stockInfos
        self.stockTrades = stockTrades
        self.transactions = transactions
    }
}

struct BackupAccount: Codable {
    let id: UUID
    let name: String
    let accountType: AccountType
    let bankSubType: BankSubType?
    let cashSubType: CashSubType?
    let bankName: String?
    let accountNumber: String?
    let brokerName: String?
    let fundHouse: String?
    let initialBalance: Decimal
    let currentBalance: Decimal
    let investedAmount: Decimal
    let totalProfitLoss: Decimal
    let currency: String
    let icon: String?
    let color: String?
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date
    let notes: String?
}

struct BackupCategory: Codable {
    let id: UUID
    let name: String
    let icon: String
    let categoryType: CategoryType
    let sortOrder: Int
    let isDefault: Bool
}

struct BackupCommittee: Codable {
    let id: UUID
    let name: String
    let monthlyAmount: Decimal
    let totalMembers: Int
    let startMonth: Date
    let myCyclePosition: Int?
    let mySlots: Int
    let mySlotPositions: String?
    let monthsCompleted: Int
    let totalSlotsPaid: Int?
    let isActive: Bool
    let createdAt: Date
}

struct BackupCommitteeContribution: Codable {
    let id: UUID
    let committeeId: UUID
    let month: Date
    let amount: Decimal
    let slots: Int?
    let sourceAccountId: UUID?
    let paidAt: Date
    let transactionId: UUID?
    let notes: String?
}

struct BackupCommitteePayout: Codable {
    let id: UUID
    let committeeId: UUID
    let month: Date
    let amount: Decimal
    let destinationAccountId: UUID
    let receivedAt: Date
    let transactionId: UUID?
    let notes: String?
}

struct BackupCommodityHolding: Codable {
    let id: UUID
    let commodityName: String
    let symbol: String
    let totalGrams: Decimal
    let avgCostPerGram: Decimal
    let totalCost: Decimal
    let totalFeesPaid: Decimal
    let currentPricePerGram: Decimal?
    let priceFetchedAt: Date?
    let createdAt: Date
}

struct BackupCommodityInfo: Codable {
    let id: UUID
    let name: String
    let currentRatePerGram: Decimal
    let lastUpdatedAt: Date?
}

struct BackupCommodityTrade: Codable {
    let id: UUID
    let holdingId: UUID
    let type: TradeType
    let commodityName: String
    let symbol: String
    let grams: Decimal
    let pricePerGram: Decimal
    let totalAmount: Decimal
    let brokerageFee: Decimal
    let tax: Decimal
    let netAmount: Decimal
    let date: Date
    let notes: String?
    let createdAt: Date
}

struct BackupCreditor: Codable {
    let id: UUID
    let name: String
    let phone: String?
    let email: String?
    let totalReceived: Decimal
    let totalReturned: Decimal
    let createdAt: Date
    let updatedAt: Date
    let notes: String?
}

struct BackupDebtor: Codable {
    let id: UUID
    let name: String
    let phone: String?
    let email: String?
    let totalLent: Decimal
    let totalRepaid: Decimal
    let createdAt: Date
    let updatedAt: Date
    let notes: String?
}

struct BackupInvestmentEntry: Codable {
    let id: UUID
    let investmentAccountId: UUID
    let type: InvestmentEntryType
    let amount: Decimal
    let date: Date
    let period: String?
    let desc: String?
    let createdAt: Date
}

struct BackupLedgerEntry: Codable {
    let id: UUID
    let transactionId: UUID
    let accountId: UUID
    let entryType: EntryType
    let amount: Decimal
    let runningBalance: Decimal
    let date: Date
    let createdAt: Date
}

struct BackupStockHolding: Codable {
    let id: UUID
    let accountId: UUID
    let companyName: String
    let ticker: String
    let totalShares: Int
    let avgCostPerShare: Decimal
    let totalCost: Decimal
    let totalFeesPaid: Decimal
    let currentPrice: Decimal?
    let priceFetchedAt: Date?
    let createdAt: Date
}

struct BackupStockInfo: Codable {
    let id: UUID
    let companyName: String
    let ticker: String
    let currentRate: Decimal
    let lastUpdatedAt: Date?
}

struct BackupStockTrade: Codable {
    let id: UUID
    let accountId: UUID
    let holdingId: UUID
    let type: TradeType
    let ticker: String
    let companyName: String
    let shares: Int
    let pricePerShare: Decimal
    let totalAmount: Decimal
    let brokerageFee: Decimal
    let tax: Decimal
    let netAmount: Decimal
    let date: Date
    let notes: String?
    let createdAt: Date
}

struct BackupTransaction: Codable {
    let id: UUID
    let type: TransactionType
    let amount: Decimal
    let date: Date
    let category: String?
    let desc: String?
    let fromAccountId: UUID?
    let toAccountId: UUID?
    let relatedEntityId: UUID?
    let createdAt: Date
    let updatedAt: Date
}

// MARK: - Service

final class DataBackupService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: Export

    func export() throws -> Data {
        let accounts: [Account] = fetchAll()
        let categories: [Category] = fetchAll()
        let committees: [Committee] = fetchAll()
        let committeeContributions: [CommitteeContribution] = fetchAll()
        let committeePayouts: [CommitteePayout] = fetchAll()
        let commodityHoldings: [CommodityHolding] = fetchAll()
        let commodityInfos: [CommodityInfo] = fetchAll()
        let commodityTrades: [CommodityTrade] = fetchAll()
        let creditors: [Creditor] = fetchAll()
        let debtors: [Debtor] = fetchAll()
        let investmentEntries: [InvestmentEntry] = fetchAll()
        let ledgerEntries: [LedgerEntry] = fetchAll()
        let stockHoldings: [StockHolding] = fetchAll()
        let stockInfos: [StockInfo] = fetchAll()
        let stockTrades: [StockTrade] = fetchAll()
        let transactions: [Transaction] = fetchAll()

        let backup = BackupData(
            accounts: accounts.map { $0.toBackup },
            categories: categories.map { $0.toBackup },
            committees: committees.map { $0.toBackup },
            committeeContributions: committeeContributions.map { $0.toBackup },
            committeePayouts: committeePayouts.map { $0.toBackup },
            commodityHoldings: commodityHoldings.map { $0.toBackup },
            commodityInfos: commodityInfos.map { $0.toBackup },
            commodityTrades: commodityTrades.map { $0.toBackup },
            creditors: creditors.map { $0.toBackup },
            debtors: debtors.map { $0.toBackup },
            investmentEntries: investmentEntries.map { $0.toBackup },
            ledgerEntries: ledgerEntries.map { $0.toBackup },
            stockHoldings: stockHoldings.map { $0.toBackup },
            stockInfos: stockInfos.map { $0.toBackup },
            stockTrades: stockTrades.map { $0.toBackup },
            transactions: transactions.map { $0.toBackup }
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(backup)
    }

    // MARK: Import

    func clearAll() throws {
        try deleteAll(Account.self)
        try deleteAll(Category.self)
        try deleteAll(Committee.self)
        try deleteAll(CommitteeContribution.self)
        try deleteAll(CommitteePayout.self)
        try deleteAll(CommodityHolding.self)
        try deleteAll(CommodityInfo.self)
        try deleteAll(CommodityTrade.self)
        try deleteAll(Creditor.self)
        try deleteAll(Debtor.self)
        try deleteAll(InvestmentEntry.self)
        try deleteAll(LedgerEntry.self)
        try deleteAll(StockHolding.self)
        try deleteAll(StockInfo.self)
        try deleteAll(StockTrade.self)
        try deleteAll(Transaction.self)
    }

    func importFrom(data: Data) throws -> Int {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(BackupData.self, from: data)

        try clearAll()

        var total = 0
        total += backup.accounts.count
        total += backup.categories.count
        total += backup.committees.count
        total += backup.committeeContributions.count
        total += backup.committeePayouts.count
        total += backup.commodityHoldings.count
        total += backup.commodityInfos.count
        total += backup.commodityTrades.count
        total += backup.creditors.count
        total += backup.debtors.count
        total += backup.investmentEntries.count
        total += backup.ledgerEntries.count
        total += backup.stockHoldings.count
        total += backup.stockInfos.count
        total += backup.stockTrades.count
        total += backup.transactions.count

        // Tier 1: No dependencies
        for item in backup.categories { modelContext.insert(item.toModel) }
        for item in backup.stockInfos { modelContext.insert(item.toModel) }
        for item in backup.commodityInfos { modelContext.insert(item.toModel) }

        // Tier 2: No dependencies
        for item in backup.accounts { modelContext.insert(item.toModel) }
        for item in backup.debtors { modelContext.insert(item.toModel) }
        for item in backup.creditors { modelContext.insert(item.toModel) }
        for item in backup.committees { modelContext.insert(item.toModel) }

        // Tier 3: Depend on Accounts
        for item in backup.stockHoldings { modelContext.insert(item.toModel) }
        for item in backup.commodityHoldings { modelContext.insert(item.toModel) }

        // Tier 4: Depend on Accounts + Holdings
        for item in backup.stockTrades { modelContext.insert(item.toModel) }
        for item in backup.commodityTrades { modelContext.insert(item.toModel) }

        // Tier 5: Depend on Accounts
        for item in backup.transactions { modelContext.insert(item.toModel) }

        // Tier 6: Depend on Transactions + Accounts
        for item in backup.ledgerEntries { modelContext.insert(item.toModel) }

        // Tier 7: Depend on Committees + Accounts
        for item in backup.committeeContributions { modelContext.insert(item.toModel) }
        for item in backup.committeePayouts { modelContext.insert(item.toModel) }

        // Tier 8: Depend on Accounts
        for item in backup.investmentEntries { modelContext.insert(item.toModel) }

        try modelContext.save()
        return total
    }

    // MARK: Helpers

    private func fetchAll<T: PersistentModel>() -> [T] {
        (try? modelContext.fetch(FetchDescriptor<T>())) ?? []
    }

    private func deleteAll<T: PersistentModel>(_ type: T.Type) throws {
        let items = try modelContext.fetch(FetchDescriptor<T>())
        for item in items {
            modelContext.delete(item)
        }
    }
}

// MARK: - Model → Backup Conversions

private extension Account {
    var toBackup: BackupAccount {
        BackupAccount(
            id: id, name: name, accountType: accountType,
            bankSubType: bankSubType, cashSubType: cashSubType,
            bankName: bankName, accountNumber: accountNumber,
            brokerName: brokerName, fundHouse: fundHouse,
            initialBalance: initialBalance, currentBalance: currentBalance,
            investedAmount: investedAmount, totalProfitLoss: totalProfitLoss,
            currency: currency, icon: icon, color: color,
            isActive: isActive, createdAt: createdAt, updatedAt: updatedAt,
            notes: notes
        )
    }
}

private extension BackupAccount {
    var toModel: Account {
        let account = Account(
            id: id, name: name, accountType: accountType,
            bankSubType: bankSubType, cashSubType: cashSubType,
            bankName: bankName, accountNumber: accountNumber,
            brokerName: brokerName, fundHouse: fundHouse,
            initialBalance: initialBalance,
            investedAmount: investedAmount,
            totalProfitLoss: totalProfitLoss,
            currency: currency, icon: icon, color: color,
            isActive: isActive, notes: notes
        )
        account.currentBalance = currentBalance
        account.createdAt = createdAt
        account.updatedAt = updatedAt
        return account
    }
}

private extension Category {
    var toBackup: BackupCategory {
        BackupCategory(id: id, name: name, icon: icon, categoryType: categoryType, sortOrder: sortOrder, isDefault: isDefault)
    }
}

private extension BackupCategory {
    var toModel: Category {
        Category(id: id, name: name, icon: icon, categoryType: categoryType, sortOrder: sortOrder, isDefault: isDefault)
    }
}

private extension Committee {
    var toBackup: BackupCommittee {
        BackupCommittee(
            id: id, name: name, monthlyAmount: monthlyAmount,
            totalMembers: totalMembers, startMonth: startMonth,
            myCyclePosition: myCyclePosition, mySlots: mySlots,
            mySlotPositions: mySlotPositions,
            monthsCompleted: monthsCompleted,
            totalSlotsPaid: totalSlotsPaid,
            isActive: isActive, createdAt: createdAt
        )
    }
}

private extension BackupCommittee {
    var toModel: Committee {
        let committee = Committee(name: name, monthlyAmount: monthlyAmount, totalMembers: totalMembers, startMonth: startMonth, myCyclePosition: myCyclePosition, mySlots: mySlots, mySlotPositions: mySlotPositions)
        committee.id = id
        committee.monthsCompleted = monthsCompleted
        committee.totalSlotsPaid = totalSlotsPaid
        committee.isActive = isActive
        committee.createdAt = createdAt
        return committee
    }
}

private extension CommitteeContribution {
    var toBackup: BackupCommitteeContribution {
        BackupCommitteeContribution(
            id: id, committeeId: committeeId, month: month,
            amount: amount, slots: slots,
            sourceAccountId: sourceAccountId,
            paidAt: paidAt, transactionId: transactionId,
            notes: notes
        )
    }
}

private extension BackupCommitteeContribution {
    var toModel: CommitteeContribution {
        let item = CommitteeContribution(
            committeeId: committeeId, month: month,
            amount: amount, sourceAccountId: sourceAccountId,
            slots: slots, notes: notes
        )
        item.id = id
        item.paidAt = paidAt
        item.transactionId = transactionId
        return item
    }
}

private extension CommitteePayout {
    var toBackup: BackupCommitteePayout {
        BackupCommitteePayout(
            id: id, committeeId: committeeId, month: month,
            amount: amount, destinationAccountId: destinationAccountId,
            receivedAt: receivedAt, transactionId: transactionId,
            notes: notes
        )
    }
}

private extension BackupCommitteePayout {
    var toModel: CommitteePayout {
        let item = CommitteePayout(
            committeeId: committeeId, month: month,
            amount: amount, destinationAccountId: destinationAccountId,
            notes: notes
        )
        item.id = id
        item.receivedAt = receivedAt
        item.transactionId = transactionId
        return item
    }
}

private extension CommodityHolding {
    var toBackup: BackupCommodityHolding {
        BackupCommodityHolding(
            id: id, commodityName: commodityName, symbol: symbol,
            totalGrams: totalGrams, avgCostPerGram: avgCostPerGram,
            totalCost: totalCost, totalFeesPaid: totalFeesPaid,
            currentPricePerGram: currentPricePerGram,
            priceFetchedAt: priceFetchedAt, createdAt: createdAt
        )
    }
}

private extension BackupCommodityHolding {
    var toModel: CommodityHolding {
        let item = CommodityHolding(
            id: id, commodityName: commodityName, symbol: symbol,
            totalGrams: totalGrams, avgCostPerGram: avgCostPerGram,
            totalCost: totalCost, totalFeesPaid: totalFeesPaid,
            currentPricePerGram: currentPricePerGram
        )
        item.priceFetchedAt = priceFetchedAt
        item.createdAt = createdAt
        return item
    }
}

private extension CommodityInfo {
    var toBackup: BackupCommodityInfo {
        BackupCommodityInfo(id: id, name: name, currentRatePerGram: currentRatePerGram, lastUpdatedAt: lastUpdatedAt)
    }
}

private extension BackupCommodityInfo {
    var toModel: CommodityInfo {
        let item = CommodityInfo(id: id, name: name, currentRatePerGram: currentRatePerGram)
        item.lastUpdatedAt = lastUpdatedAt
        return item
    }
}

private extension CommodityTrade {
    var toBackup: BackupCommodityTrade {
        BackupCommodityTrade(
            id: id, holdingId: holdingId, type: type,
            commodityName: commodityName, symbol: symbol,
            grams: grams, pricePerGram: pricePerGram,
            totalAmount: totalAmount, brokerageFee: brokerageFee,
            tax: tax, netAmount: netAmount, date: date,
            notes: notes, createdAt: createdAt
        )
    }
}

private extension BackupCommodityTrade {
    var toModel: CommodityTrade {
        CommodityTrade(
            id: id, holdingId: holdingId, type: type,
            commodityName: commodityName, symbol: symbol,
            grams: grams, pricePerGram: pricePerGram,
            totalAmount: totalAmount, brokerageFee: brokerageFee,
            tax: tax, netAmount: netAmount, date: date,
            notes: notes
        )
    }
}

private extension Creditor {
    var toBackup: BackupCreditor {
        BackupCreditor(
            id: id, name: name, phone: phone, email: email,
            totalReceived: totalReceived, totalReturned: totalReturned,
            createdAt: createdAt, updatedAt: updatedAt, notes: notes
        )
    }
}

private extension BackupCreditor {
    var toModel: Creditor {
        let item = Creditor(id: id, name: name, phone: phone, email: email, totalReceived: totalReceived, totalReturned: totalReturned, notes: notes)
        item.createdAt = createdAt
        item.updatedAt = updatedAt
        return item
    }
}

private extension Debtor {
    var toBackup: BackupDebtor {
        BackupDebtor(
            id: id, name: name, phone: phone, email: email,
            totalLent: totalLent, totalRepaid: totalRepaid,
            createdAt: createdAt, updatedAt: updatedAt, notes: notes
        )
    }
}

private extension BackupDebtor {
    var toModel: Debtor {
        let item = Debtor(id: id, name: name, phone: phone, email: email, totalLent: totalLent, totalRepaid: totalRepaid, notes: notes)
        item.createdAt = createdAt
        item.updatedAt = updatedAt
        return item
    }
}

private extension InvestmentEntry {
    var toBackup: BackupInvestmentEntry {
        BackupInvestmentEntry(
            id: id, investmentAccountId: investmentAccountId,
            type: type, amount: amount, date: date,
            period: period, desc: desc, createdAt: createdAt
        )
    }
}

private extension BackupInvestmentEntry {
    var toModel: InvestmentEntry {
        InvestmentEntry(
            id: id, investmentAccountId: investmentAccountId,
            type: type, amount: amount, date: date,
            period: period, description: desc
        )
    }
}

private extension LedgerEntry {
    var toBackup: BackupLedgerEntry {
        BackupLedgerEntry(
            id: id, transactionId: transactionId,
            accountId: accountId, entryType: entryType,
            amount: amount, runningBalance: runningBalance,
            date: date, createdAt: createdAt
        )
    }
}

private extension BackupLedgerEntry {
    var toModel: LedgerEntry {
        LedgerEntry(
            id: id, transactionId: transactionId,
            accountId: accountId, entryType: entryType,
            amount: amount, runningBalance: runningBalance,
            date: date
        )
    }
}

private extension StockHolding {
    var toBackup: BackupStockHolding {
        BackupStockHolding(
            id: id, accountId: accountId,
            companyName: companyName, ticker: ticker,
            totalShares: totalShares,
            avgCostPerShare: avgCostPerShare,
            totalCost: totalCost, totalFeesPaid: totalFeesPaid,
            currentPrice: currentPrice,
            priceFetchedAt: priceFetchedAt, createdAt: createdAt
        )
    }
}

private extension BackupStockHolding {
    var toModel: StockHolding {
        let item = StockHolding(
            id: id, accountId: accountId,
            companyName: companyName, ticker: ticker,
            totalShares: totalShares,
            avgCostPerShare: avgCostPerShare,
            totalCost: totalCost, totalFeesPaid: totalFeesPaid,
            currentPrice: currentPrice
        )
        item.priceFetchedAt = priceFetchedAt
        item.createdAt = createdAt
        return item
    }
}

private extension StockInfo {
    var toBackup: BackupStockInfo {
        BackupStockInfo(id: id, companyName: companyName, ticker: ticker, currentRate: currentRate, lastUpdatedAt: lastUpdatedAt)
    }
}

private extension BackupStockInfo {
    var toModel: StockInfo {
        let item = StockInfo(id: id, companyName: companyName, ticker: ticker, currentRate: currentRate)
        item.lastUpdatedAt = lastUpdatedAt
        return item
    }
}

private extension StockTrade {
    var toBackup: BackupStockTrade {
        BackupStockTrade(
            id: id, accountId: accountId, holdingId: holdingId,
            type: type, ticker: ticker,
            companyName: companyName, shares: shares,
            pricePerShare: pricePerShare,
            totalAmount: totalAmount,
            brokerageFee: brokerageFee, tax: tax,
            netAmount: netAmount, date: date, notes: notes,
            createdAt: createdAt
        )
    }
}

private extension BackupStockTrade {
    var toModel: StockTrade {
        StockTrade(
            id: id, accountId: accountId, holdingId: holdingId,
            type: type, ticker: ticker,
            companyName: companyName, shares: shares,
            pricePerShare: pricePerShare,
            totalAmount: totalAmount,
            brokerageFee: brokerageFee, tax: tax,
            netAmount: netAmount, date: date, notes: notes
        )
    }
}

private extension Transaction {
    var toBackup: BackupTransaction {
        BackupTransaction(
            id: id, type: type, amount: amount, date: date,
            category: category, desc: desc,
            fromAccountId: fromAccountId,
            toAccountId: toAccountId,
            relatedEntityId: relatedEntityId,
            createdAt: createdAt, updatedAt: updatedAt
        )
    }
}

private extension BackupTransaction {
    var toModel: Transaction {
        Transaction(
            id: id, type: type, amount: amount, date: date,
            category: category, description: desc,
            fromAccountId: fromAccountId,
            toAccountId: toAccountId,
            relatedEntityId: relatedEntityId
        )
    }
}
