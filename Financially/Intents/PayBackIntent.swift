import Foundation
import AppIntents
import SwiftData

struct PayBackIntent: AppIntent {
    static var title: LocalizedStringResource = "Pay Back Creditor"
    static var description: LocalizedStringResource = "Pay back money to a creditor"
    static var authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    @Parameter(title: "Creditor", requestValueDialog: "Who to pay back?")
    var creditor: CreditorEntity

    @Parameter(title: "Amount", requestValueDialog: "How much?")
    var amount: Double

    @Parameter(title: "Bank Account", requestValueDialog: "From which bank account?")
    var bankAccount: AccountEntity

    @Parameter(title: "Date")
    var date: Date?

    @Parameter(title: "Notes")
    var notes: String?

    @MainActor
    func perform() async throws -> some IntentResult {
        let creditorId = creditor.id
        let bankAccountId = bankAccount.id
        do {
            let context = ModelContainer.financially.mainContext
            guard let person = try? context.fetch(FetchDescriptor<Creditor>(predicate: #Predicate { $0.id == creditorId })).first else {
                throw IntentError.failed("Creditor not found.")
            }
            guard let bank = try? context.fetch(FetchDescriptor<Account>(predicate: #Predicate { $0.id == bankAccountId })).first else {
                throw IntentError.failed("Bank account not found.")
            }

            let amountDecimal = Decimal(amount)
            guard amountDecimal <= person.outstandingBalance else {
                throw IntentError.failed("Payback exceeds outstanding balance of \(person.outstandingBalance.formattedCurrency()).")
            }
            let service = LedgerService(modelContext: context)

            person.totalReturned += amountDecimal
            person.updatedAt = Date()

            let request = TransactionRequest(
                type: .liabilityPayback,
                amount: amountDecimal,
                date: date ?? Date(),
                description: notes ?? "Payback to \(person.name)",
                sourceAccountId: bank.id,
                relatedEntityId: person.id
            )
            do {
                try service.execute(request)
            } catch {
                person.totalReturned -= amountDecimal
                throw error
            }
            try context.save()

            return .result(dialog: "Paid back \(amountDecimal.formattedCurrency()) to \(person.name).")
        } catch let error as ValidationError {
            throw IntentError.failed(errorMessage(from: error))
        } catch {
            throw IntentError.failed(error.localizedDescription)
        }
    }
}
