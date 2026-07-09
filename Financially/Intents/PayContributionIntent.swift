import Foundation
import AppIntents
import SwiftData

struct PayContributionIntent: AppIntent {
    static var title: LocalizedStringResource = "Pay Committee Contribution"
    static var description: LocalizedStringResource = "Pay monthly committee contribution"
    static var authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    @Parameter(title: "Committee", requestValueDialog: "Which committee?")
    var committee: CommitteeEntity

    @Parameter(title: "Amount", requestValueDialog: "How much?")
    var amount: Double

    @Parameter(title: "Bank Account", requestValueDialog: "From which bank account?")
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
            let totalSlots = comm.totalMembers * comm.mySlots
            guard (comm.totalSlotsPaid ?? 0) < totalSlots else {
                throw IntentError.failed("All contributions for this committee are complete.")
            }

            let monthOffset = (comm.totalSlotsPaid ?? 0) / comm.mySlots
            let calendar = Calendar.current
            let adjusted = calendar.date(byAdding: .month, value: monthOffset, to: comm.startMonth) ?? comm.startMonth
            let monthDate = calendar.date(from: calendar.dateComponents([.year, .month], from: adjusted)) ?? adjusted

            let service = LedgerService(modelContext: context)
            let request = TransactionRequest(
                type: .committeeContribution,
                amount: amountDecimal,
                date: Date(),
                description: notes ?? "Committee: \(comm.name) - Month \(monthOffset + 1)",
                sourceAccountId: bank.id,
                relatedEntityId: comm.id
            )
            try service.execute(request)

            let contribution = CommitteeContribution(
                committeeId: comm.id, month: monthDate,
                amount: amountDecimal, sourceAccountId: bank.id, notes: notes
            )
            context.insert(contribution)

            comm.totalSlotsPaid = (comm.totalSlotsPaid ?? 0) + 1
            comm.monthsCompleted = (comm.totalSlotsPaid ?? 0) / comm.mySlots
            if comm.monthsCompleted >= comm.totalMembers { comm.isActive = false }
            try context.save()

            return .result(dialog: "Paid \(amountDecimal.formattedCurrency()) contribution to \(comm.name).")
        } catch let error as ValidationError {
            throw IntentError.failed(errorMessage(from: error))
        } catch {
            throw IntentError.failed(error.localizedDescription)
        }
    }
}
