import SwiftUI
import SwiftData

struct DebtorsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Debtor.name) private var debtors: [Debtor]
    @State private var showCreate = false

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
                Section {
                    VStack(spacing: 16) {
                        ZStack {
                            Image(systemName: "person.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.blue)
                                .offset(x: 18, y: 18)
                        }
                        Text("No Debtors")
                            .font(.title3.bold())
                        Text("Add someone you've lent money to")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Add Debtor") { showCreate = true }
                            .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                }
            }
        }
        .navigationTitle("Debtors")
        .toolbar {
            ToolbarItem {
                Button(action: { showCreate = true }) {
                    Label("Add Debtor", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreate) {
            PersonFormView(title: "New Debtor") { name, phone, email in
                let debtor = Debtor(name: name, phone: phone, email: email)
                modelContext.insert(debtor)
            }
        }
    }
}

struct DebtorRowView: View {
    let debtor: Debtor

    var body: some View {
        DebtorCreditorRowView(
            name: debtor.name,
            phone: debtor.phone,
            email: debtor.email,
            outstandingBalance: debtor.outstandingBalance,
            balanceColor: .primary,
            isSettled: debtor.isSettled
        )
    }
}