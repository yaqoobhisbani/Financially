import SwiftUI
import SwiftData

struct CreditorsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Creditor.name) private var creditors: [Creditor]
    @State private var showCreate = false

    var activeCreditors: [Creditor] { creditors.filter { !$0.isSettled } }
    var settledCreditors: [Creditor] { creditors.filter { $0.isSettled } }

    var body: some View {
        List {
            if !activeCreditors.isEmpty {
                Section("Active (\(activeCreditors.count))") {
                    ForEach(activeCreditors) { creditor in
                        NavigationLink(destination: CreditorDetailView(creditor: creditor)) {
                            CreditorRowView(creditor: creditor)
                        }
                    }
                }
            }

            if !settledCreditors.isEmpty {
                Section("Settled (\(settledCreditors.count))") {
                    ForEach(settledCreditors) { creditor in
                        NavigationLink(destination: CreditorDetailView(creditor: creditor)) {
                            CreditorRowView(creditor: creditor)
                        }
                    }
                }
            }

            if creditors.isEmpty {
                Section {
                    EmptyStateView(
                        title: "No Creditors",
                        systemImage: "person.fill.questionmark",
                        description: "Add someone whose money you're holding",
                        buttonLabel: "Add Creditor",
                        action: { showCreate = true }
                    )
                }
            }
        }
        .navigationTitle("Creditors")
        .toolbar {
            ToolbarItem {
                Button(action: { showCreate = true }) {
                    Label("Add Creditor", systemImage: "plus")
                }
                .buttonStyle(.glassProminent)
            }
        }
        .sheet(isPresented: $showCreate) {
            PersonFormView(title: "New Creditor") { name, phone, email in
                let creditor = Creditor(name: name, phone: phone, email: email)
                modelContext.insert(creditor)
            }
        }
    }
}

struct CreditorRowView: View {
    let creditor: Creditor

    var body: some View {
        DebtorCreditorRowView(
            name: creditor.name,
            phone: creditor.phone,
            email: creditor.email,
            outstandingBalance: creditor.outstandingBalance,
            balanceColor: .orange,
            isSettled: creditor.isSettled
        )
    }
}