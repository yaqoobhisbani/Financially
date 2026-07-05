import SwiftUI
import SwiftData

struct CommitteesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Committee.createdAt, order: .reverse) private var allCommittees: [Committee]
    @State private var showCreate = false

    private var activeCommittees: [Committee] {
        allCommittees.filter { $0.isActive && !$0.isComplete }
    }

    private var completedCommittees: [Committee] {
        allCommittees.filter { $0.isComplete || !$0.isActive }
    }

    var body: some View {
        NavigationStack {
            List {
                if activeCommittees.isEmpty && completedCommittees.isEmpty {
                    emptyState
                } else {
                    if !activeCommittees.isEmpty {
                        Section("Active") {
                            ForEach(activeCommittees) { committee in
                                NavigationLink(destination: CommitteeDetailView(committee: committee)) {
                                    committeeRow(committee)
                                }
                            }
                        }
                    }
                    if !completedCommittees.isEmpty {
                        Section("Completed") {
                            ForEach(completedCommittees) { committee in
                                NavigationLink(destination: CommitteeDetailView(committee: committee)) {
                                    committeeRow(committee)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Committees")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreate = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreate) {
                CreateCommitteeView()
            }
        }
    }

    private func committeeRow(_ committee: Committee) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(committee.name)
                    .font(.subheadline.bold())
                Spacer()
                Text("PKR \(committee.monthlyAmount.formatted())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("\(committee.monthsCompleted)/\(committee.totalMembers) months")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(committee.totalContributed.formattedCurrency())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private var emptyState: some View {
        Section {
            EmptyStateView(
                title: "No Committees",
                systemImage: "person.3.fill",
                description: "Create a committee to start saving with your group",
                buttonLabel: "Create Committee",
                action: { showCreate = true }
            )
        }
    }
}
