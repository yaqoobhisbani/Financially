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
                GlassSegmentedControl(options: CommitteeSegment.allCases, selection: $selectedSegment) { $0.rawValue }
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
                .scrollContentBackground(.hidden)
            }
            .groupedScreenBackground()
            .navigationTitle("Committees")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreate = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.glassProminent)
                }
            }
            .sheet(isPresented: $showCreate) {
                CreateCommitteeView()
            }
        }
    }

    private func committeeRow(_ committee: Committee) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "person.3.fill")
                .font(.title3)
                .foregroundStyle(.teal)
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(committee.name)
                    .font(.headline)
                    .lineLimit(1)
                Text("\(committee.monthsCompleted)/\(committee.totalMembers) months")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(committee.monthlyAmount.formattedCurrency())
                    .font(.headline)
                    .tabularNumbers()
                    .fixedSize(horizontal: true, vertical: false)
                Text(committee.totalContributed.formattedCurrency())
                    .font(.caption)
                    .tabularNumbers()
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
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
