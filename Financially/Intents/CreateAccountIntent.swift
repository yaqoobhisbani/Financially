import Foundation
import AppIntents
import SwiftData

struct CreateAccountIntent: AppIntent {
    static var title: LocalizedStringResource = "Create Account"
    static var description: LocalizedStringResource = "Create a new bank or cash account"
    static var authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    @Parameter(title: "Name", requestValueDialog: "What is the account name?")
    var name: String

    @Parameter(title: "Type", requestValueDialog: "Is it bank or cash?")
    var type: String

    @Parameter(title: "Bank Name")
    var bankName: String?

    @Parameter(title: "Initial Balance", requestValueDialog: "What is the initial balance?")
    var initialBalance: Double?

    @Parameter(title: "Notes")
    var notes: String?

    @MainActor
    func perform() async throws -> some IntentResult {
        let isBank = type.lowercased() == "bank"
        let balance = initialBalance.flatMap { Decimal($0) } ?? 0

        let account = Account(
            name: name,
            accountType: isBank ? .bank : .cash,
            bankName: isBank ? bankName : nil,
            initialBalance: balance
        )
        let context = ModelContainer.financially.mainContext
        context.insert(account)
        try context.save()

        return .result(dialog: "Created \(isBank ? "bank" : "cash") account \"\(name)\" with \(balance.formattedCurrency()).")
    }
}
