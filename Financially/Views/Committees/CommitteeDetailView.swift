import SwiftUI
import SwiftData

struct CommitteeDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let committee: Committee

    @State private var showPayContribution = false
    @State private var showReceivePayout = false
    @State private var contributionToDelete: CommitteeContribution?
    @State private var payoutToDelete: CommitteePayout?
    @State private var showDeleteCommittee = false

    @Query private var contributions: [CommitteeContribution]
    @Query private var payouts: [CommitteePayout]

    init(committee: Committee) {
        self.committee = committee
        let committeeId = committee.id
        let contributionPredicate = #Predicate<CommitteeContribution> { $0.committeeId == committeeId }
        _contributions = Query(filter: contributionPredicate, sort: \.paidAt, order: .reverse)
        let payoutPredicate = #Predicate<CommitteePayout> { $0.committeeId == committeeId }
        _payouts = Query(filter: payoutPredicate, sort: \.receivedAt, order: .reverse)
    }

    private var remainingPayout: Decimal {
        max(0, committee.myTotalPayout - payouts.reduce(0) { $0 + $1.amount })
    }

    var body: some View {
        List {
            headerSection
            progressSection
            if !committee.isComplete || remainingPayout > 0 {
                actionsSection
            }
            if !contributions.isEmpty {
                contributionsSection
            }
            if !payouts.isEmpty {
                payoutsSection
            }
        }
        .navigationTitle(committee.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(role: .destructive) {
                    showDeleteCommittee = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .sheet(isPresented: $showPayContribution) {
            PayContributionView(committee: committee)
        }
        .sheet(isPresented: $showReceivePayout) {
            ReceivePayoutView(committee: committee)
        }
        .alert("Delete Committee", isPresented: $showDeleteCommittee) {
            Button("Delete", role: .destructive) { deleteCommittee() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this committee and all its records? This action cannot be undone.")
        }
        .alert("Delete Contribution", isPresented: .init(
            get: { contributionToDelete != nil },
            set: { if !$0 { contributionToDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let c = contributionToDelete {
                    deleteContribution(c)
                }
                contributionToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                contributionToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this contribution record? This action cannot be undone.")
        }
        .alert("Delete Payout", isPresented: .init(
            get: { payoutToDelete != nil },
            set: { if !$0 { payoutToDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let p = payoutToDelete {
                    deletePayout(p)
                }
                payoutToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                payoutToDelete = nil
            }
        } message: {
            Text("Are you sure you want to delete this payout record? This action cannot be undone.")
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        Section {
            VStack(spacing: 8) {
                HStack(spacing: 0) {
                    SummaryItem(title: "Monthly", value: committee.monthlyAmount.formattedCurrency(), alignment: .leading)
                    SummaryItem(title: "Members", value: "\(committee.totalMembers)", alignment: .center)
                    SummaryItem(title: "Payout", value: committee.totalPayout.formattedCurrency(), alignment: .trailing)
                }
                if committee.mySlots > 1 {
                    HStack(spacing: 0) {
                        let label = committee.slotPositionList.isEmpty ? "\(committee.mySlots)" : committee.slotPositionList.map(String.init).joined(separator: ", ")
                        SummaryItem(title: "My Slots", value: label, alignment: .leading)
                        SummaryItem(title: "", value: "", alignment: .center)
                        SummaryItem(title: "My Total", value: committee.myTotalPayout.formattedCurrency(), alignment: .trailing)
                    }
                    .padding(.vertical, 4)
                } else if !committee.slotPositionList.isEmpty {
                    HStack(spacing: 0) {
                        SummaryItem(title: "My Slot", value: committee.slotPositionList.map(String.init).joined(separator: ", "), alignment: .leading)
                        SummaryItem(title: "", value: "", alignment: .center)
                        SummaryItem(title: "", value: "", alignment: .trailing)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Progress

    private var progressSection: some View {
        Section("Progress") {
            VStack(spacing: 8) {
                ProgressView(value: Double(committee.monthsCompleted), total: Double(committee.totalMembers))
                    .tint(.blue)
                HStack {
                    Text("\(committee.monthsCompleted) of \(committee.totalMembers) months")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if !committee.slotPositionList.isEmpty {
                        Text("My slot(s): \(committee.slotPositionList.map(String.init).joined(separator: ", "))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else if let pos = committee.myCyclePosition {
                        Text("My slot: #\(pos)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                if committee.isComplete {
                    Label("Completed", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
        }
    }

    // MARK: - Actions

    private var actionsSection: some View {
        Section {
            if !committee.isComplete {
                Button {
                    showPayContribution = true
                } label: {
                    Label("Pay Month \(committee.monthsCompleted + 1)", systemImage: "arrow.up.circle")
                }
            }

            if remainingPayout > 0 {
                Button {
                    showReceivePayout = true
                } label: {
                    Label("Receive Payout (\(remainingPayout.formattedCurrency()))", systemImage: "arrow.down.circle.fill")
                }
            }
        }
    }

    // MARK: - Contributions

    private var contributionsSection: some View {
        Section("Contributions") {
            ForEach(contributions) { contribution in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(contribution.month, format: .dateTime.month().year())
                            .font(.subheadline)
                        if let slotCount = contribution.slots, slotCount > 1 {
                            Text("×\(slotCount) slots")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if let notes = contribution.notes {
                            Text(notes)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Text(contribution.amount.formattedCurrency())
                        .font(.subheadline.bold())
                }
                .swipeActions(edge: .trailing) {
                    Button("Delete", role: .destructive) {
                        contributionToDelete = contribution
                    }
                }
            }
        }
    }

    // MARK: - Payouts

    private var payoutsSection: some View {
        Section("Payouts Received") {
            ForEach(payouts) { payout in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(payout.month, formatter: monthYearFormatter)
                            .font(.subheadline)
                        if let notes = payout.notes {
                            Text(notes)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Text(payout.amount.formattedCurrency())
                        .font(.subheadline.bold())
                        .foregroundStyle(.green)
                }
                .swipeActions(edge: .trailing) {
                    Button("Delete", role: .destructive) {
                        payoutToDelete = payout
                    }
                }
            }
        }
    }

    // MARK: - Delete

    private func deleteContribution(_ contribution: CommitteeContribution) {
        if let txnId = contribution.transactionId {
            let fetch = FetchDescriptor<Transaction>(predicate: #Predicate { $0.id == txnId })
            if let transaction = try? modelContext.fetch(fetch).first {
                let manager = LedgerManager(modelContext: modelContext)
                try? manager.deleteTransaction(transaction)
            }
        }
        modelContext.delete(contribution)
        try? modelContext.save()
    }

    private func deletePayout(_ payout: CommitteePayout) {
        if let txnId = payout.transactionId {
            let fetch = FetchDescriptor<Transaction>(predicate: #Predicate { $0.id == txnId })
            if let transaction = try? modelContext.fetch(fetch).first {
                let manager = LedgerManager(modelContext: modelContext)
                try? manager.deleteTransaction(transaction)
            }
        }
        modelContext.delete(payout)
        try? modelContext.save()
    }

    private func deleteCommittee() {
        let allContributions = contributions
        let allPayouts = payouts
        for contribution in allContributions {
            deleteContribution(contribution)
        }
        for payout in allPayouts {
            deletePayout(payout)
        }
        modelContext.delete(committee)
        try? modelContext.save()
        dismiss()
    }
}

private let monthYearFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "MMM yyyy"
    return f
}()

struct SummaryItem: View {
    let title: String
    let value: String
    var alignment: HorizontalAlignment = .center

    var body: some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.bold())
        }
        .frame(maxWidth: .infinity, alignment: Alignment(horizontal: alignment, vertical: .center))
    }
}
