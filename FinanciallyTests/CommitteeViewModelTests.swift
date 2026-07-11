import Testing
import Foundation
import SwiftData
@testable import Financially

@MainActor
@Suite("CommitteeViewModel")
struct CommitteeViewModelTests {

    private func makeCommittee(in context: ModelContext, monthlyAmount: Decimal = 1000, totalMembers: Int = 10, mySlots: Int = 1) -> Committee {
        let committee = Committee(name: "Family", monthlyAmount: monthlyAmount, totalMembers: totalMembers, startMonth: Date(), mySlots: mySlots)
        context.insert(committee)
        return committee
    }

    // MARK: - payContribution

    @Test func payContributionDebitsAccountAndAdvancesProgress() throws {
        let context = TestSupport.makeContext()
        let account = TestSupport.makeAccount(in: context, name: "Bank", type: .bank, initialBalance: 5000)
        let committee = makeCommittee(in: context)
        let vm = CommitteeViewModel(modelContext: context)

        try vm.payContribution(committee: committee, sourceAccountId: account.id, slots: 1, notes: nil)

        #expect(account.currentBalance == 4000)
        #expect(committee.totalSlotsPaid == 1)
        #expect(committee.monthsCompleted == 1)
        #expect(vm.contributions(for: committee.id).count == 1)
    }

    @Test func payContributionWithMultipleSlotsChargesProportionally() throws {
        let context = TestSupport.makeContext()
        let account = TestSupport.makeAccount(in: context, name: "Bank", type: .bank, initialBalance: 10_000)
        let committee = makeCommittee(in: context, monthlyAmount: 1000, mySlots: 2)
        let vm = CommitteeViewModel(modelContext: context)

        try vm.payContribution(committee: committee, sourceAccountId: account.id, slots: 2, notes: nil)

        #expect(account.currentBalance == 8000) // 2 slots * 1000
        #expect(committee.totalSlotsPaid == 2)
        #expect(committee.monthsCompleted == 1) // 2 slots paid / mySlots(2) = 1 month
    }

    @Test func payContributionMarksCommitteeInactiveWhenComplete() throws {
        let context = TestSupport.makeContext()
        let account = TestSupport.makeAccount(in: context, name: "Bank", type: .bank, initialBalance: 10_000)
        let committee = makeCommittee(in: context, totalMembers: 1)
        let vm = CommitteeViewModel(modelContext: context)

        try vm.payContribution(committee: committee, sourceAccountId: account.id, slots: 1, notes: nil)

        #expect(committee.isComplete)
        #expect(!committee.isActive)
    }

    @Test func payContributionThrowsWhenAllSlotsAlreadyPaid() throws {
        let context = TestSupport.makeContext()
        let account = TestSupport.makeAccount(in: context, name: "Bank", type: .bank, initialBalance: 10_000)
        let committee = makeCommittee(in: context, totalMembers: 1)
        let vm = CommitteeViewModel(modelContext: context)
        try vm.payContribution(committee: committee, sourceAccountId: account.id, slots: 1, notes: nil)

        #expect(throws: CommitteeViewModel.CommitteeError.self) {
            try vm.payContribution(committee: committee, sourceAccountId: account.id, slots: 1, notes: nil)
        }
        #expect(account.currentBalance == 9000) // unaffected by the rejected second call
    }

    // MARK: - receivePayout

    @Test func receivePayoutCreditsAccountAndRecordsPayout() throws {
        let context = TestSupport.makeContext()
        let account = TestSupport.makeAccount(in: context, name: "Bank", type: .bank, initialBalance: 0)
        let committee = makeCommittee(in: context, monthlyAmount: 1000, totalMembers: 10)
        let vm = CommitteeViewModel(modelContext: context)

        try vm.receivePayout(committee: committee, destinationAccountId: account.id, amount: 10_000, notes: nil)

        #expect(account.currentBalance == 10_000)
        #expect(vm.payouts(for: committee.id).count == 1)
    }

    @Test func receivePayoutRejectsAmountExceedingTotalPayout() throws {
        let context = TestSupport.makeContext()
        let account = TestSupport.makeAccount(in: context, name: "Bank", type: .bank, initialBalance: 0)
        let committee = makeCommittee(in: context, monthlyAmount: 1000, totalMembers: 10) // totalPayout = 10,000
        let vm = CommitteeViewModel(modelContext: context)

        #expect(throws: CommitteeViewModel.CommitteeError.self) {
            try vm.receivePayout(committee: committee, destinationAccountId: account.id, amount: 15_000, notes: nil)
        }
        #expect(account.currentBalance == 0)
    }

    @Test func receivePayoutCapUsesMyTotalPayoutForMultiSlotCommittees() throws {
        // Regression: a 2-slot holder is entitled to 2x the pool payout, not capped at a single slot's share.
        let context = TestSupport.makeContext()
        let account = TestSupport.makeAccount(in: context, name: "Bank", type: .bank, initialBalance: 0)
        let committee = makeCommittee(in: context, monthlyAmount: 1000, totalMembers: 10, mySlots: 2) // myTotalPayout = 20,000
        let vm = CommitteeViewModel(modelContext: context)

        try vm.receivePayout(committee: committee, destinationAccountId: account.id, amount: 20_000, notes: nil)

        #expect(account.currentBalance == 20_000)
    }

    @Test func receivePayoutAccumulatesAcrossMultipleCalls() throws {
        let context = TestSupport.makeContext()
        let account = TestSupport.makeAccount(in: context, name: "Bank", type: .bank, initialBalance: 0)
        let committee = makeCommittee(in: context, monthlyAmount: 1000, totalMembers: 10)
        let vm = CommitteeViewModel(modelContext: context)

        try vm.receivePayout(committee: committee, destinationAccountId: account.id, amount: 6000, notes: nil)
        try vm.receivePayout(committee: committee, destinationAccountId: account.id, amount: 4000, notes: nil)

        #expect(account.currentBalance == 10_000)
        #expect(vm.payouts(for: committee.id).count == 2)

        // A further payout would now exceed the pool total and must be rejected.
        #expect(throws: CommitteeViewModel.CommitteeError.self) {
            try vm.receivePayout(committee: committee, destinationAccountId: account.id, amount: 1, notes: nil)
        }
    }

    @Test func toggleActiveFlipsIsActive() {
        let context = TestSupport.makeContext()
        let committee = makeCommittee(in: context)
        let vm = CommitteeViewModel(modelContext: context)
        #expect(committee.isActive)

        vm.toggleActive(committee)
        #expect(!committee.isActive)

        vm.toggleActive(committee)
        #expect(committee.isActive)
    }
}
