import Foundation
import AppIntents
import SwiftData

struct RecordRepaymentIntent: AppIntent {
    static var title: LocalizedStringResource = "Record Repayment"
    static var description: LocalizedStringResource = "Record a repayment from a debtor"
    static var authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    @Parameter(title: "Debtor", requestValueDialog: "Who is repaying?")
    var debtor: DebtorEntity

    @Parameter(title: "Amount", requestValueDialog: "How much?")
    var amount: Double

    @Parameter(title: "Bank Account", requestValueDialog: "To which bank account?")
    var bankAccount: AccountEntity

    @Parameter(title: "Date")
    var date: Date?

    @Parameter(title: "Notes")
    var notes: String?

    @MainActor
    func perform() async throws -> some IntentResult {
        let debtorId = debtor.id
        let bankAccountId = bankAccount.id
        do {
            let context = ModelContainer.financially.mainContext
            guard let person = try? context.fetch(FetchDescriptor<Debtor>(predicate: #Predicate { $0.id == debtorId })).first else {
                throw IntentError.failed("Debtor not found.")
            }
            guard let bank = try? context.fetch(FetchDescriptor<Account>(predicate: #Predicate { $0.id == bankAccountId })).first else {
                throw IntentError.failed("Bank account not found.")
            }

            let amountDecimal = Decimal(amount)
            guard amountDecimal <= person.outstandingBalance else {
                throw IntentError.failed("Repayment exceeds outstanding balance of \(person.outstandingBalance.formattedCurrency()).")
            }
            let service = LedgerService(modelContext: context)

            person.totalRepaid += amountDecimal
            person.updatedAt = Date()

            let request = TransactionRequest(
                type: .loanRepayment,
                amount: amountDecimal,
                date: date ?? Date(),
                description: notes ?? "Repayment from \(person.name)",
                destinationAccountId: bank.id,
                relatedEntityId: person.id
            )
            do {
                try service.execute(request)
            } catch {
                person.totalRepaid -= amountDecimal
                throw error
            }
            try context.save()

            return .result(dialog: "Recorded repayment of \(amountDecimal.formattedCurrency()) from \(person.name).")
        } catch let error as ValidationError {
            throw IntentError.failed(errorMessage(from: error))
        } catch {
            throw IntentError.failed(error.localizedDescription)
        }
    }
}
