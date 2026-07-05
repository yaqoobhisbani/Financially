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
                    VStack(spacing: 16) {
                        ZStack {
                            Image(systemName: "person.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                            Image(systemName: "arrow.left.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.orange)
                                .offset(x: -18, y: 18)
                        }
                        Text("No Creditors")
                            .font(.title3.bold())
                        Text("Add someone whose money you're holding")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Add Creditor") { showCreate = true }
                            .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                }
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