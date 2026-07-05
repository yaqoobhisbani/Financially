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
                        emptyState
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

    private var emptyState: some View {
        Section {
            VStack(spacing: 12) {
                Image(systemName: selectedSegment == .banks ? "building.columns.fill" : "wallet.pass.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
                Text(selectedSegment == .banks ? "No Bank Accounts" : "No Cash Accounts")
                    .font(.headline)
                Text(selectedSegment == .banks ? "Add a bank account to track your bank balances" : "Add a cash account to track your cash on hand")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button(selectedSegment == .banks ? "Add Bank Account" : "Add Cash Account") {
                    showCreateSheet = true
                }
                .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        }
    }
}