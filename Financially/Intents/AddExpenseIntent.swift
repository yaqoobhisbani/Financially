import Foundation
import AppIntents
import SwiftData

struct AddExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Expense"
    static var description: LocalizedStringResource = "Record an expense transaction"
    static var authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    @Parameter(title: "Amount", requestValueDialog: "How much was the expense?")
    var amount: Double

    @Parameter(title: "Category", requestValueDialog: "What category?")
    var category: ExpenseCategoryEntity

    @Parameter(title: "Account", requestValueDialog: "From which account?")
    var account: AccountEntity

    @Parameter(title: "Date")
    var date: Date?

    @Parameter(title: "Notes")
    var notes: String?

    @MainActor
    func perform() async throws -> some IntentResult {
        do {
            let context = ModelContainer.financially.mainContext
            let request = TransactionRequest(
                type: .expense,
                amount: Decimal(amount),
                date: date ?? Date(),
                category: category.name,
                description: notes,
                sourceAccountId: account.id
            )
            try LedgerService(modelContext: context).execute(request)
            try context.save()
            return .result(dialog: "Expense of Rs \(amount.formatted(.number.precision(.fractionLength(0...2)))) added.")
        } catch let error as ValidationError {
            throw IntentError.invalidSelection(errorMessage(from: error))
        } catch {
            throw IntentError.failed(error.localizedDescription)
        }
    }

    enum IntentError: Error, CustomLocalizedStringResourceConvertible {
        case invalidSelection(String)
        case failed(String)

        var localizedStringResource: LocalizedStringResource {
            switch self {
            case .invalidSelection(let message):
                return LocalizedStringResource(stringLiteral: message)
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
