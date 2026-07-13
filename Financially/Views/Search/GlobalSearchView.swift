import SwiftUI
import SwiftData

struct GlobalSearchView: View {
    @Query(sort: \Account.name) private var accounts: [Account]
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query(sort: \Debtor.name) private var debtors: [Debtor]
    @Query(sort: \Creditor.name) private var creditors: [Creditor]
    @Query(sort: \Committee.name) private var committees: [Committee]
    @Query private var stockHoldings: [StockHolding]
    @Query private var mfHoldings: [MutualFundHolding]
    @Query private var commodityHoldings: [CommodityHolding]

    @State private var query = ""

    private var hasQuery: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var matchedAccounts: [Account] {
        guard hasQuery else { return [] }
        return accounts.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    private var matchedStockHoldings: [StockHolding] {
        guard hasQuery else { return [] }
        return stockHoldings.filter {
            $0.companyName.localizedCaseInsensitiveContains(query) || $0.ticker.localizedCaseInsensitiveContains(query)
        }
    }

    private var matchedMFHoldings: [MutualFundHolding] {
        guard hasQuery else { return [] }
        return mfHoldings.filter {
            $0.schemeName.localizedCaseInsensitiveContains(query) || $0.fundCode.localizedCaseInsensitiveContains(query)
        }
    }

    private var matchedCommodityHoldings: [CommodityHolding] {
        guard hasQuery else { return [] }
        return commodityHoldings.filter { $0.commodityName.localizedCaseInsensitiveContains(query) }
    }

    private var matchedDebtors: [Debtor] {
        guard hasQuery else { return [] }
        return debtors.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    private var matchedCreditors: [Creditor] {
        guard hasQuery else { return [] }
        return creditors.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    private var matchedCommittees: [Committee] {
        guard hasQuery else { return [] }
        return committees.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    private var matchedTransactions: [Transaction] {
        guard hasQuery else { return [] }
        return Array(transactions.filter {
            ($0.desc?.localizedCaseInsensitiveContains(query) ?? false)
                || ($0.category?.localizedCaseInsensitiveContains(query) ?? false)
                || $0.type.displayLabel.localizedCaseInsensitiveContains(query)
        }.prefix(25))
    }

    private var hasAnyResults: Bool {
        !matchedAccounts.isEmpty || !matchedStockHoldings.isEmpty || !matchedMFHoldings.isEmpty
            || !matchedCommodityHoldings.isEmpty || !matchedDebtors.isEmpty || !matchedCreditors.isEmpty
            || !matchedCommittees.isEmpty || !matchedTransactions.isEmpty
    }

    var body: some View {
        NavigationStack {
            Group {
                if !hasQuery {
                    ContentUnavailableView(
                        "Search Financially",
                        systemImage: "magnifyingglass",
                        description: Text("Find accounts, holdings, transactions, people, and committees.")
                    )
                } else if !hasAnyResults {
                    ContentUnavailableView.search(text: query)
                } else {
                    resultsList
                }
            }
            .navigationTitle("Search")
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Accounts, transactions, people…")
        }
    }

    private var resultsList: some View {
        List {
            if !matchedAccounts.isEmpty {
                Section("Accounts") {
                    ForEach(matchedAccounts) { account in
                        NavigationLink(destination: AccountDetailView(account: account)) {
                            AccountRowView(account: account, holdings: stockHoldings)
                        }
                    }
                }
            }

            if !matchedStockHoldings.isEmpty || !matchedMFHoldings.isEmpty || !matchedCommodityHoldings.isEmpty {
                Section("Holdings") {
                    ForEach(matchedStockHoldings) { holding in
                        if let account = accounts.first(where: { $0.id == holding.accountId }) {
                            NavigationLink(destination: HoldingDetailView(account: account, holding: holding)) {
                                searchRow(title: holding.companyName, subtitle: holding.ticker, systemImage: "chart.bar.fill", tint: .indigo)
                            }
                        }
                    }
                    ForEach(matchedMFHoldings) { holding in
                        if let account = accounts.first(where: { $0.id == holding.accountId }) {
                            NavigationLink(destination: MFHoldingDetailView(account: account, holding: holding)) {
                                searchRow(title: holding.schemeName, subtitle: holding.fundCode, systemImage: "chart.pie.fill", tint: .teal)
                            }
                        }
                    }
                    ForEach(matchedCommodityHoldings) { holding in
                        NavigationLink(destination: CommodityHoldingDetailView(holding: holding)) {
                            searchRow(title: holding.commodityName, subtitle: "\(holding.totalGrams.formattedNumber()) g", systemImage: "diamond.fill", tint: .orange)
                        }
                    }
                }
            }

            if !matchedDebtors.isEmpty || !matchedCreditors.isEmpty {
                Section("People") {
                    ForEach(matchedDebtors) { debtor in
                        NavigationLink(destination: DebtorDetailView(debtor: debtor)) {
                            DebtorCreditorRowView(
                                name: debtor.name,
                                phone: debtor.phone,
                                email: debtor.email,
                                outstandingBalance: debtor.outstandingBalance,
                                balanceColor: .loss,
                                isSettled: debtor.isSettled
                            )
                        }
                    }
                    ForEach(matchedCreditors) { creditor in
                        NavigationLink(destination: CreditorDetailView(creditor: creditor)) {
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
                }
            }

            if !matchedCommittees.isEmpty {
                Section("Committees") {
                    ForEach(matchedCommittees) { committee in
                        NavigationLink(destination: CommitteeDetailView(committee: committee)) {
                            searchRow(title: committee.name, subtitle: "\(committee.totalMembers) members", systemImage: "person.3.fill", tint: .teal)
                        }
                    }
                }
            }

            if !matchedTransactions.isEmpty {
                Section("Transactions") {
                    ForEach(matchedTransactions) { transaction in
                        NavigationLink(destination: TransactionDetailView(transaction: transaction)) {
                            TransactionRowView(transaction: transaction, showIcon: true)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func searchRow(title: String, subtitle: String, systemImage: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.subheadline)
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)
                .background(tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
