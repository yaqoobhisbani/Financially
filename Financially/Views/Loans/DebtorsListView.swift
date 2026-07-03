import SwiftUI
import SwiftData

struct DebtorsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Debtor.name) private var debtors: [Debtor]
    @State private var showCreateDebtor = false
    @State private var newDebtorName = ""

    var activeDebtors: [Debtor] { debtors.filter { !$0.isSettled } }
    var settledDebtors: [Debtor] { debtors.filter { $0.isSettled } }

    var body: some View {
        List {
            if !activeDebtors.isEmpty {
                Section("Active (\(activeDebtors.count))") {
                    ForEach(activeDebtors) { debtor in
                        NavigationLink(destination: DebtorDetailView(debtor: debtor)) {
                            DebtorRowView(debtor: debtor)
                        }
                    }
                }
            }

            if !settledDebtors.isEmpty {
                Section("Settled (\(settledDebtors.count))") {
                    ForEach(settledDebtors) { debtor in
                        NavigationLink(destination: DebtorDetailView(debtor: debtor)) {
                            DebtorRowView(debtor: debtor)
                        }
                    }
                }
            }

            if debtors.isEmpty {
                ContentUnavailableView(
                    "No Debtors",
                    systemImage: "person.fill.questionmark",
                    description: Text("Add someone you've lent money to")
                )
            }
        }
        .navigationTitle("Debtors")
        .toolbar {
            ToolbarItem {
                Button(action: { showCreateDebtor = true }) {
                    Label("Add Debtor", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreateDebtor) {
            NavigationStack {
                Form {
                    TextField("Name", text: $newDebtorName)
                }
                .navigationTitle("New Debtor")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showCreateDebtor = false; newDebtorName = "" }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            let debtor = Debtor(name: newDebtorName)
                            modelContext.insert(debtor)
                            newDebtorName = ""
                            showCreateDebtor = false
                        }
                        .disabled(newDebtorName.isEmpty)
                    }
                }
            }
        }
    }
}

struct DebtorRowView: View {
    let debtor: Debtor

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(debtor.name)
                    .font(.headline)
                if let phone = debtor.phone {
                    Text(phone)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(debtor.outstandingBalance.formattedCurrency())
                    .font(.headline)
                    .foregroundStyle(debtor.outstandingBalance > 0 ? .primary : .secondary)
                if debtor.isSettled {
                    Text("Settled")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .opacity(debtor.isSettled ? 0.6 : 1)
    }
}