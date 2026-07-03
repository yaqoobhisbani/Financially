import SwiftUI
import SwiftData

struct CreditorsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Creditor.name) private var creditors: [Creditor]
    @State private var showCreateCreditor = false
    @State private var newCreditorName = ""

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
                ContentUnavailableView(
                    "No Creditors",
                    systemImage: "person.fill.questionmark",
                    description: Text("Add someone whose money you're holding")
                )
            }
        }
        .navigationTitle("Creditors")
        .toolbar {
            ToolbarItem {
                Button(action: { showCreateCreditor = true }) {
                    Label("Add Creditor", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreateCreditor) {
            NavigationStack {
                Form {
                    TextField("Name", text: $newCreditorName)
                }
                .navigationTitle("New Creditor")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showCreateCreditor = false; newCreditorName = "" }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add") {
                            let creditor = Creditor(name: newCreditorName)
                            modelContext.insert(creditor)
                            newCreditorName = ""
                            showCreateCreditor = false
                        }
                        .disabled(newCreditorName.isEmpty)
                    }
                }
            }
        }
    }
}

struct CreditorRowView: View {
    let creditor: Creditor

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(creditor.name)
                    .font(.headline)
                if let phone = creditor.phone {
                    Text(phone)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(creditor.outstandingBalance.formattedCurrency())
                    .font(.headline)
                    .foregroundStyle(creditor.outstandingBalance > 0 ? .orange : .secondary)
                if creditor.isSettled {
                    Text("Settled")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .opacity(creditor.isSettled ? 0.6 : 1)
    }
}