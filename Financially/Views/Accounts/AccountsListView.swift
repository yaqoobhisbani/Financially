import SwiftUI
import SwiftData

struct AccountsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var accounts: [Account]
    @Query private var allHoldings: [StockHolding]
    @State private var selectedSegment: AccountSegment = .banks
    @State private var showCreateSheet = false

    private enum AccountSegment: String, CaseIterable {
        case banks = "Banks"
        case cash = "Cash"
    }

    private var filteredAccounts: [Account] {
        switch selectedSegment {
        case .banks:
            return accounts.filter { $0.accountType == .bank }
        case .cash:
            return accounts.filter { $0.accountType == .cash }
        }
    }

    private var preSelectedType: AccountType {
        selectedSegment == .banks ? .bank : .cash
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Segment", selection: $selectedSegment) {
                    ForEach(AccountSegment.allCases, id: \.self) { segment in
                        Text(segment.rawValue).tag(segment)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                List {
                    if filteredAccounts.isEmpty {
                        Text("No \(selectedSegment.rawValue.lowercased()) accounts yet. Tap + to add one.")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    }
                    ForEach(filteredAccounts) { account in
                        NavigationLink(destination: AccountDetailView(account: account)) {
                            AccountRowView(account: account, holdings: allHoldings)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Accounts")
            .toolbar {
                ToolbarItem {
                    Button(action: { showCreateSheet = true }) {
                        Label("Add Account", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                CreateAccountView(accountType: preSelectedType)
            }
        }
    }
}