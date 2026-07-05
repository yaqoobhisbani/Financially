import SwiftUI
import SwiftData

struct CommitteesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Committee.createdAt, order: .reverse) private var allCommittees: [Committee]
    @State private var selectedSegment: CommitteeSegment = .active
    @State private var showCreate = false

    private enum CommitteeSegment: String, CaseIterable {
        case active = "Active"
        case inactive = "Inactive"
    }

    private var filteredCommittees: [Committee] {
        switch selectedSegment {
        case .active:
            return allCommittees.filter { $0.isActive && !$0.isComplete }
        case .inactive:
            return allCommittees.filter { $0.isComplete || !$0.isActive }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Segment", selection: $selectedSegment) {
                    ForEach(CommitteeSegment.allCases, id: \.self) { segment in
                        Text(segment.rawValue).tag(segment)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                List {
                    if filteredCommittees.isEmpty {
                        emptyState
                    } else {
                        ForEach(filteredCommittees) { committee in
                            NavigationLink(destination: CommitteeDetailView(committee: committee)) {
                                committeeRow(committee)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
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
                title: selectedSegment == .active ? "No Active Committees" : "No Inactive Committees",
                systemImage: "person.3.fill",
                description: selectedSegment == .active ? "Create a committee to start saving with your group" : "Completed or deactivated committees will appear here",
                buttonLabel: selectedSegment == .active ? "Create Committee" : nil,
                action: selectedSegment == .active ? { showCreate = true } : nil
            )
        }
    }
}
