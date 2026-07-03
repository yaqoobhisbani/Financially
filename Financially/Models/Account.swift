import Foundation
import SwiftData

@Model
final class Account {
    @Attribute(.unique) var id: UUID
    var name: String
    var accountType: AccountType
    var bankSubType: BankSubType?
    var cashSubType: CashSubType?
    var bankName: String?
    var accountNumber: String?
    var brokerName: String?
    var fundHouse: String?
    var initialBalance: Decimal
    var currentBalance: Decimal
    var investedAmount: Decimal
    var totalProfitLoss: Decimal
    var currency: String
    var icon: String?
    var color: String?
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date
    var notes: String?

    var currentValue: Decimal {
        if accountType == .psx {
            return investedAmount + totalProfitLoss
        }
        return currentBalance
    }

    var returnPercentage: Decimal {
        guard investedAmount > 0 else { return 0 }
        return (totalProfitLoss / investedAmount) * 100
    }

    @Relationship(deleteRule: .cascade)
    var ledgerEntries: [LedgerEntry]?

    func syncFromHoldings(_ holdings: [StockHolding]) {
        guard accountType == .psx else { return }
        investedAmount = holdings.reduce(0) { $0 + $1.totalCost }
        totalProfitLoss = holdings.reduce(0) { $0 + $1.currentValue - $1.totalCost }
    }

    init(
        id: UUID = UUID(),
        name: String,
        accountType: AccountType,
        bankSubType: BankSubType? = nil,
        cashSubType: CashSubType? = nil,
        bankName: String? = nil,
        accountNumber: String? = nil,
        brokerName: String? = nil,
        fundHouse: String? = nil,
        initialBalance: Decimal = 0,
        investedAmount: Decimal = 0,
        totalProfitLoss: Decimal = 0,
        currency: String = "PKR",
        icon: String? = nil,
        color: String? = nil,
        isActive: Bool = true,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.accountType = accountType
        self.bankSubType = bankSubType
        self.cashSubType = cashSubType
        self.bankName = bankName
        self.accountNumber = accountNumber
        self.brokerName = brokerName
        self.fundHouse = fundHouse
        self.initialBalance = initialBalance
        self.currentBalance = initialBalance
        self.investedAmount = investedAmount
        self.totalProfitLoss = totalProfitLoss
        self.currency = currency
        self.icon = icon
        self.color = color
        self.isActive = isActive
        self.createdAt = Date()
        self.updatedAt = Date()
        self.notes = notes
    }
}