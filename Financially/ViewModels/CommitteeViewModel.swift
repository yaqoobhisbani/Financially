import Foundation
import SwiftData

@Observable
final class CommitteeViewModel {
    private let modelContext: ModelContext
    private let ledgerService: LedgerService
    private let ledgerManager: LedgerManager

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.ledgerService = LedgerService(modelContext: modelContext)
        self.ledgerManager = LedgerManager(modelContext: modelContext)
    }

    // MARK: - Queries

    var committees: [Committee] {
        (try? modelContext.fetch(FetchDescriptor<Committee>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))) ?? []
    }

    func contributions(for committeeId: UUID) -> [CommitteeContribution] {
        let predicate = #Predicate<CommitteeContribution> { $0.committeeId == committeeId }
        return (try? modelContext.fetch(FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.paidAt, order: .reverse)]))) ?? []
    }

    func payouts(for committeeId: UUID) -> [CommitteePayout] {
        let predicate = #Predicate<CommitteePayout> { $0.committeeId == committeeId }
        return (try? modelContext.fetch(FetchDescriptor(predicate: predicate, sortBy: [SortDescriptor(\.receivedAt, order: .reverse)]))) ?? []
    }

    var activeCommittees: [Committee] {
        committees.filter { $0.isActive && !$0.isComplete }
    }

    var completedCommittees: [Committee] {
        committees.filter { $0.isComplete || !$0.isActive }
    }

    // MARK: - Actions

    func createCommittee(name: String, monthlyAmount: Decimal, totalMembers: Int, startMonth: Date, cyclePosition: Int?, monthsCompleted: Int = 0) {
        let committee = Committee(
            name: name,
            monthlyAmount: monthlyAmount,
            totalMembers: totalMembers,
            startMonth: startMonth,
            myCyclePosition: cyclePosition
        )
        committee.monthsCompleted = monthsCompleted
        if monthsCompleted >= totalMembers {
            committee.isActive = false
        }
        modelContext.insert(committee)
        try? modelContext.save()
    }

    func payContribution(committee: Committee, sourceAccountId: UUID?, notes: String?) throws {
        guard committee.monthsCompleted < committee.totalMembers else { return }

        let monthDate = currentCommitteeMonth(offset: committee.monthsCompleted, from: committee.startMonth)

        let request = TransactionRequest(
            type: .committeeContribution,
            amount: committee.monthlyAmount,
            date: Date(),
            description: "Committee: \(committee.name) - Month \(committee.monthsCompleted + 1)",
            sourceAccountId: sourceAccountId,
            relatedEntityId: committee.id
        )

        try ledgerService.execute(request)

        let contribution = CommitteeContribution(
            committeeId: committee.id,
            month: monthDate,
            amount: committee.monthlyAmount,
            sourceAccountId: sourceAccountId,
            notes: notes
        )
        modelContext.insert(contribution)

        committee.monthsCompleted += 1

        if committee.monthsCompleted >= committee.totalMembers {
            committee.isActive = false
        }

        try modelContext.save()
    }

    func receivePayout(committee: Committee, destinationAccountId: UUID, amount: Decimal, notes: String?) throws {
        let totalReceived = payouts(for: committee.id).reduce(0) { $0 + $1.amount }
        guard totalReceived + amount <= committee.totalPayout else { return }

        let request = TransactionRequest(
            type: .committeePayout,
            amount: amount,
            date: Date(),
            description: "Committee Payout: \(committee.name)",
            sourceAccountId: destinationAccountId,
            destinationAccountId: destinationAccountId,
            relatedEntityId: committee.id
        )

        try ledgerService.execute(request)

        let payout = CommitteePayout(
            committeeId: committee.id,
            month: Date(),
            amount: amount,
            destinationAccountId: destinationAccountId,
            notes: notes
        )
        modelContext.insert(payout)

        try modelContext.save()
    }

    func toggleActive(_ committee: Committee) {
        committee.isActive.toggle()
        try? modelContext.save()
    }
}

private func currentCommitteeMonth(offset: Int, from date: Date) -> Date {
    let calendar = Calendar.current
    let adjusted = calendar.date(byAdding: .month, value: offset, to: date) ?? date
    return calendar.date(from: calendar.dateComponents([.year, .month], from: adjusted)) ?? adjusted
}