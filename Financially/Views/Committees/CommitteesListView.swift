import SwiftUI

struct CommitteesListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var vm: CommitteeViewModel?
    @State private var showCreate = false

    var body: some View {
        NavigationStack {
            if let vm {
                content(vm)
            }
        }
        .onAppear {
            vm = CommitteeViewModel(modelContext: modelContext)
        }
        .sheet(isPresented: $showCreate) {
            CreateCommitteeView()
        }
    }

    private func content(_ vm: CommitteeViewModel) -> some View {
        List {
            if vm.activeCommittees.isEmpty && vm.completedCommittees.isEmpty {
                emptyState
            } else {
                if !vm.activeCommittees.isEmpty {
                    Section("Active") {
                        ForEach(vm.activeCommittees) { committee in
                            NavigationLink(destination: CommitteeDetailView(committee: committee)) {
                                committeeRow(committee)
                            }
                        }
                    }
                }
                if !vm.completedCommittees.isEmpty {
                    Section("Completed") {
                        ForEach(vm.completedCommittees) { committee in
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
            VStack(spacing: 12) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
                Text("No Committees")
                    .font(.headline)
                Text("Create a committee to start saving with your group")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Create Committee") {
                    showCreate = true
                }
                .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        }
    }
}