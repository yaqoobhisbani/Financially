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
                GlassSegmentedControl(options: AccountSegment.allCases, selection: $selectedSegment) { $0.rawValue }
                    .padding()

                List {
                    if filteredAccounts.isEmpty {
                        emptyState
                    }
                    ForEach(filteredAccounts) { account in
                        NavigationLink(destination: AccountDetailView(account: account)) {
                            AccountRowView(account: account, holdings: allHoldings)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .groupedScreenBackground()
            .navigationTitle("Accounts")
            .toolbar {
                ToolbarItem {
                    Button(action: { showCreateSheet = true }) {
                        Label("Add Account", systemImage: "plus")
                    }
                    .buttonStyle(.glass)
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                CreateAccountView(accountType: preSelectedType)
            }
        }
    }

    private var emptyState: some View {
        Section {
            EmptyStateView(
                title: selectedSegment == .banks ? "No Bank Accounts" : "No Cash Accounts",
                systemImage: selectedSegment == .banks ? "building.columns.fill" : "wallet.pass.fill",
                description: selectedSegment == .banks ? "Add a bank account to track your bank balances" : "Add a cash account to track your cash on hand",
                buttonLabel: selectedSegment == .banks ? "Add Bank Account" : "Add Cash Account",
                action: { showCreateSheet = true }
            )
        }
    }
}