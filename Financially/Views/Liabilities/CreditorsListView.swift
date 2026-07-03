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
                Button(action: { showCreate = true }) {
                    Label("Add Creditor", systemImage: "plus")
                }
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
        HStack {
            VStack(alignment: .leading) {
                Text(creditor.name)
                    .font(.headline)
                if let phone = creditor.phone {
                    Text(phone)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let email = creditor.email {
                    Text(email)
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