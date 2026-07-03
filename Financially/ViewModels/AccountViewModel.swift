import Foundation
import SwiftData

@Observable
final class AccountViewModel {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func createAccount(name: String, accountType: AccountType, bankSubType: BankSubType? = nil, cashSubType: CashSubType? = nil, bankName: String? = nil, accountNumber: String? = nil, brokerName: String? = nil, fundHouse: String? = nil, initialBalance: Decimal = 0, investedAmount: Decimal = 0, currency: String = "PKR", icon: String? = nil, color: String? = nil, notes: String? = nil) throws {
        let account = Account(
            name: name,
            accountType: accountType,
            bankSubType: bankSubType,
            cashSubType: cashSubType,
            bankName: bankName,
            accountNumber: accountNumber,
            brokerName: brokerName,
            fundHouse: fundHouse,
            initialBalance: initialBalance,
            investedAmount: investedAmount,
            currency: currency,
            icon: icon,
            color: color,
            notes: notes
        )
        modelContext.insert(account)
        try modelContext.save()
    }

    func deactivateAccount(_ account: Account) {
        account.isActive = false
        account.updatedAt = Date()
    }

    func reactivateAccount(_ account: Account) {
        account.isActive = true
        account.updatedAt = Date()
    }

    func updateAccount(_ account: Account, name: String? = nil, icon: String? = nil, color: String? = nil, notes: String? = nil) {
        if let name = name { account.name = name }
        if let icon = icon { account.icon = icon }
        if let color = color { account.color = color }
        if let notes = notes { account.notes = notes }
        account.updatedAt = Date()
    }
}