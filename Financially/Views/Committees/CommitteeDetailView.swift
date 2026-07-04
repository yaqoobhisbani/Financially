import SwiftUI

struct CommitteeDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let committee: Committee

    @State private var showPayContribution = false
    @State private var showReceivePayout = false
    @State private var contributions: [CommitteeContribution] = []
    @State private var payouts: [CommitteePayout] = []

    private var vm: CommitteeViewModel {
        CommitteeViewModel(modelContext: modelContext)
    }

    var body: some View {
        List {
            headerSection
            progressSection
            if !committee.isComplete {
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
        .onAppear {
            reload()
        }
        .sheet(isPresented: $showPayContribution) {
            PayContributionView(committee: committee)
        }
        .sheet(isPresented: $showReceivePayout) {
            ReceivePayoutView(committee: committee)
        }
    }

    private func reload() {
        contributions = vm.contributions(for: committee.id)
        payouts = vm.payouts(for: committee.id)
    }

    // MARK: - Header

    private var headerSection: some View {
        Section {
            VStack(spacing: 8) {
                HStack {
                    SummaryItem(title: "Monthly", value: committee.monthlyAmount.formattedCurrency())
                    Spacer()
                    SummaryItem(title: "Payout", value: committee.totalPayout.formattedCurrency())
                    Spacer()
                    SummaryItem(title: "Members", value: "\(committee.totalMembers)")
                }
                .padding(.vertical, 4)
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
                    if let pos = committee.myCyclePosition {
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
            Button {
                showPayContribution = true
            } label: {
                Label("Pay Month \(committee.monthsCompleted + 1)", systemImage: "arrow.up.circle")
            }

            Button {
                showReceivePayout = true
            } label: {
                Label("Receive Payout", systemImage: "arrow.down.circle.fill")
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
            }
        }
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

    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.bold())
        }
    }
}