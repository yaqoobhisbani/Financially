import Foundation
import AppIntents
import SwiftData

struct GiveLoanIntent: AppIntent {
    static var title: LocalizedStringResource = "Give Loan"
    static var description: LocalizedStringResource = "Record a loan given to someone"
    static var authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    @Parameter(title: "Person Name", requestValueDialog: "Who did you lend to?")
    var personName: String

    @Parameter(title: "Amount", requestValueDialog: "How much?")
    var amount: Double

    @Parameter(title: "Account", requestValueDialog: "From which account?")
    var account: AccountEntity?

    @Parameter(title: "Date")
    var date: Date?

    @Parameter(title: "Notes")
    var notes: String?

    @MainActor
    func perform() async throws -> some IntentResult {
        do {
            let context = ModelContainer.financially.mainContext

            let debtorFetch = FetchDescriptor<Debtor>(predicate: #Predicate { $0.name == personName })
            let debtor: Debtor
            if let existing = try? context.fetch(debtorFetch).first {
                debtor = existing
            } else {
                debtor = Debtor(name: personName, notes: notes)
                context.insert(debtor)
            }

            debtor.totalLent += Decimal(amount)
            debtor.updatedAt = Date()

            let request = TransactionRequest(
                type: .loanGiven,
                amount: Decimal(amount),
                date: date ?? Date(),
                description: notes ?? "Loan given to \(personName)",
                sourceAccountId: account?.id,
                relatedEntityId: debtor.id
            )
            try LedgerService(modelContext: context).execute(request)
            try context.save()

            return .result(dialog: "Loan of Rs \(amount.formatted(.number.precision(.fractionLength(0...2)))) given to \(personName).")
        } catch let error as ValidationError {
            throw IntentError.failed(errorMessage(from: error))
        } catch {
            throw IntentError.failed(error.localizedDescription)
        }
    }

    enum IntentError: Error, CustomLocalizedStringResourceConvertible {
        case failed(String)

        var localizedStringResource: LocalizedStringResource {
            switch self {
            case .failed(let message):
                return LocalizedStringResource(stringLiteral: message)
            }
        }
    }

    private func errorMessage(from error: ValidationError) -> String {
        switch error {
        case .insufficientBalance(let name, _, _):
            return "Insufficient balance in \(name)."
        case .amountMustBePositive:
            return "Amount must be positive."
        case .accountNotFound:
            return "Selected account not found."
        case .accountNotActive:
            return "Selected account is not active."
        case .accountTypeMismatch:
            return "Please select a bank or cash account."
        case .futureDateNotAllowed:
            return "Date cannot be in the future."
        default:
            return "Validation failed."
        }
    }
}
