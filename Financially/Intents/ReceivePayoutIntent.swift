import Foundation
import AppIntents
import SwiftData

struct ReceivePayoutIntent: AppIntent {
    static var title: LocalizedStringResource = "Receive Committee Payout"
    static var description: LocalizedStringResource = "Receive a committee payout"
    static var authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    @Parameter(title: "Committee", requestValueDialog: "Which committee?")
    var committee: CommitteeEntity

    @Parameter(title: "Amount", requestValueDialog: "How much?")
    var amount: Double

    @Parameter(title: "Bank Account", requestValueDialog: "To which bank account?")
    var bankAccount: AccountEntity

    @Parameter(title: "Notes")
    var notes: String?

    @MainActor
    func perform() async throws -> some IntentResult {
        let committeeId = committee.id
        let bankAccountId = bankAccount.id
        do {
            let context = ModelContainer.financially.mainContext
            guard let comm = try? context.fetch(FetchDescriptor<Committee>(predicate: #Predicate { $0.id == committeeId })).first else {
                throw IntentError.failed("Committee not found.")
            }
            guard let bank = try? context.fetch(FetchDescriptor<Account>(predicate: #Predicate { $0.id == bankAccountId })).first else {
                throw IntentError.failed("Bank account not found.")
            }

            let amountDecimal = Decimal(amount)
            let payoutCommitteeId = comm.id
            let payouts = (try? context.fetch(FetchDescriptor<CommitteePayout>(predicate: #Predicate { $0.committeeId == payoutCommitteeId }))) ?? []
            let totalReceived = payouts.reduce(0) { $0 + $1.amount }
            guard totalReceived + amountDecimal <= comm.myTotalPayout else {
                throw IntentError.failed("Total payout would exceed \(comm.myTotalPayout.formattedCurrency()).")
            }

            let service = LedgerService(modelContext: context)
            let request = TransactionRequest(
                type: .committeePayout,
                amount: amountDecimal,
                date: Date(),
                description: notes ?? "Committee Payout: \(comm.name)",
                destinationAccountId: bank.id,
                relatedEntityId: comm.id
            )
            try service.execute(request)

            let payout = CommitteePayout(
                committeeId: comm.id, month: Date(),
                amount: amountDecimal, destinationAccountId: bank.id, notes: notes
            )
            context.insert(payout)
            try context.save()

            return .result(dialog: "Received \(amountDecimal.formattedCurrency()) payout from \(comm.name).")
        } catch let error as ValidationError {
            throw IntentError.failed(errorMessage(from: error))
        } catch {
            throw IntentError.failed(error.localizedDescription)
        }
    }
}
