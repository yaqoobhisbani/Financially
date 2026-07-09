import Foundation
import AppIntents
import SwiftData

struct TransferMoneyIntent: AppIntent {
    static var title: LocalizedStringResource = "Transfer Money"
    static var description: LocalizedStringResource = "Transfer money between accounts"
    static var authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    @Parameter(title: "Source Account", requestValueDialog: "From which account?")
    var sourceAccount: AccountEntity

    @Parameter(title: "Destination Account", requestValueDialog: "To which account?")
    var destinationAccount: AccountEntity

    @Parameter(title: "Amount", requestValueDialog: "How much?")
    var amount: Double

    @Parameter(title: "Date")
    var date: Date?

    @Parameter(title: "Notes")
    var notes: String?

    @MainActor
    func perform() async throws -> some IntentResult {
        guard sourceAccount.id != destinationAccount.id else {
            throw IntentError.invalidSelection("Source and destination must be different accounts.")
        }

        do {
            let context = ModelContainer.financially.mainContext
            let request = TransactionRequest(
                type: .transfer,
                amount: Decimal(amount),
                date: date ?? Date(),
                description: notes,
                sourceAccountId: sourceAccount.id,
                destinationAccountId: destinationAccount.id
            )
            try LedgerService(modelContext: context).execute(request)
            try context.save()

            return .result(dialog: "Transferred Rs \(amount.formatted(.number.precision(.fractionLength(0...2)))) from \(sourceAccount.name) to \(destinationAccount.name).")
        } catch let error as ValidationError {
            throw IntentError.failed(errorMessage(from: error))
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
        case .selfTransfer:
            return "Source and destination must be different."
        case .transferToInvestmentAccount:
            return "Cannot transfer to an investment account."
        case .accountTypeMismatch:
            return "Please select bank or cash accounts."
        case .futureDateNotAllowed:
            return "Date cannot be in the future."
        default:
            return "Validation failed."
        }
    }
}
