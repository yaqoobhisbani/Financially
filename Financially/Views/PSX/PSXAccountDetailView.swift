import SwiftUI
import SwiftData

struct PSXAccountDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let account: Account

    @State private var vm: PSXPortfolioViewModel?
    @State private var showStatement = false
    @State private var showEdit = false
    @State private var selectedTransaction: Transaction?
    @State private var showBuy = false
    @State private var showSell = false
    @State private var showAddCash = false
    @State private var showWithdraw = false

    var body: some View {
        if let vm {
            content(vm: vm)
        } else {
            ProgressView()
                .onAppear {
                    vm = PSXPortfolioViewModel(modelContext: modelContext, account: account)
                }
        }
    }

    private func content(vm: PSXPortfolioViewModel) -> some View {
        List {
            balanceSection(vm: vm)
            actionsSection(vm: vm)
            holdingsSection(vm: vm)
            recentTransactionsSection(vm: vm)
        }
        .navigationTitle(account.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("View Statement", systemImage: "doc.text") { showStatement = true }
                    Button("Edit Account", systemImage: "pencil") { showEdit = true }
                    Button(account.isActive ? "Deactivate" : "Activate", systemImage: account.isActive ? "eye.slash" : "eye") {
                        vm.toggleActive()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showStatement) { AccountStatementView(account: account) }
        .sheet(isPresented: $showEdit) { EditAccountView(account: account) }
        .sheet(isPresented: $showBuy) { BuySharesView(account: account) }
        .sheet(isPresented: $showSell) { SellSharesView(account: account) }
        .sheet(isPresented: $showAddCash) { PSXAddCashView(account: account) }
        .sheet(isPresented: $showWithdraw) { PSXWithdrawCashView(account: account) }
    }

    // MARK: - Balance

    private func balanceSection(vm: PSXPortfolioViewModel) -> some View {
        Section {
            SummaryBalanceView(
                heroLeftLabel: "Total Portfolio",
                heroLeftValue: (account.currentBalance + vm.totalHoldingValue).formattedCurrency(currency: account.currency),
                heroRightLabel: "P&L",
                heroRightValue: vm.totalUnrealizedPAndL.formattedCurrency(currency: account.currency),
                heroRightColor: vm.totalUnrealizedPAndL >= 0 ? .incomeGreen : .expenseRed,
                detailRows: [
                    [
                        AnyView(SummaryMetric(label: "Available Cash", value: account.currentBalance.formattedCurrency(currency: account.currency))),
                        AnyView(SummaryMetric(label: "Holdings Value", value: vm.totalHoldingValue.formattedCurrency(currency: account.currency), color: .incomeGreen, alignment: .trailing))
                    ],
                    [
                        AnyView(SummaryMetric(label: "Total Cost", value: vm.totalCostBasis.formattedCurrency(currency: account.currency))),
                        AnyView(SummaryMetricView(label: "Return", alignment: .trailing) { PercentageText(value: vm.totalPAndLPercentage).foregroundStyle(vm.totalUnrealizedPAndL >= 0 ? .incomeGreen : .expenseRed) })
                    ]
                ]
            )
        }
    }

    // MARK: - Actions

    private func actionsSection(vm: PSXPortfolioViewModel) -> some View {
        Section {
            HStack(spacing: 10) {
                ActionCard(label: "Buy", icon: "plus.circle.fill", color: .incomeGreen) { showBuy = true }
                ActionCard(label: "Sell", icon: "minus.circle.fill", color: .expenseRed) { showSell = true }
                ActionCard(label: "Add Cash", icon: "arrow.down.circle.fill", color: .blue) { showAddCash = true }
                ActionCard(label: "Withdraw", icon: "arrow.up.circle.fill", color: .orange) { showWithdraw = true }
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        } header: {
            Text("Actions")
        }
    }

    // MARK: - Holdings

    private func holdingsSection(vm: PSXPortfolioViewModel) -> some View {
        Section("Holdings") {
            if vm.accountHoldings.isEmpty {
                EmptyStateView(title: "No holdings yet", systemImage: "chart.bar.xaxis", description: "Buy shares to get started")
            }
            ForEach(vm.accountHoldings) { holding in
                NavigationLink(destination: HoldingDetailView(account: account, holding: holding)) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(holding.companyName)
                                .font(.headline)
                            Text(holding.ticker)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack(spacing: 4) {
                                Text("\(holding.totalShares) shares")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                Text("@")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                Text(holding.avgCostPerShare.formattedCurrency(currency: account.currency))
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(holding.currentValue.formattedCurrency(currency: account.currency))
                                .font(.subheadline.bold())
                            Text(holding.unrealizedPAndL.formattedCurrency(currency: account.currency))
                                .font(.caption)
                                .foregroundStyle(holding.unrealizedPAndL >= 0 ? .incomeGreen : .expenseRed)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Recent Transactions

    private func recentTransactionsSection(vm: PSXPortfolioViewModel) -> some View {
        Section("Recent Transactions") {
            ForEach(Array(vm.ledgerEntries.prefix(20))) { entry in
                LedgerRowView(entry: entry, currency: account.currency)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedTransaction = vm.transaction(for: entry)
                    }
            }

            if vm.ledgerEntries.isEmpty {
                EmptyStateView(title: "No transactions yet", systemImage: "arrow.left.arrow.right")
            }
        }
        .sheet(item: $selectedTransaction) { tx in
            NavigationStack { TransactionDetailView(transaction: tx) }
        }
    }
}

// MARK: - PSX Cash Flow Views

struct PSXAddCashView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let account: Account

    @Query private var accounts: [Account]
    @State private var sourceAccount: Account?
    @State private var amount = ""
    @State private var date = Date()
    @State private var showAccountPicker = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Source Account") {
                    Button(action: { showAccountPicker = true }) {
                        HStack {
                            Text("From")
                            Spacer()
                            if let account = sourceAccount {
                                Text(account.name).foregroundStyle(.primary)
                            } else {
                                Text("Select account").foregroundStyle(.secondary)
                            }
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Amount") {
                    AmountField(amount: $amount)
                }

                Section { DatePicker("Date", selection: $date, displayedComponents: .date) }

                FormErrorSection(message: errorMessage)
            }
            .navigationTitle("Add Cash")
            .formToolbar(label: "Add", isDisabled: sourceAccount == nil || amount.isEmpty) { save() }
            .sheet(isPresented: $showAccountPicker) {
                AccountPickerView(accounts: accounts, title: "Select Source", filterType: nil) { account in
                    sourceAccount = account
                }
            }
        }
    }

    private func save() {
        guard let source = sourceAccount else { errorMessage = "Please select a source account"; return }
        guard let amountValue = Decimal(string: amount), amountValue > 0 else { errorMessage = "Please enter a valid amount"; return }

        let service = LedgerService(modelContext: modelContext)
        let request = TransactionRequest(
            type: .investmentAddCapital,
            amount: amountValue,
            date: date,
            description: "Add cash to PSX account",
            sourceAccountId: source.id,
            destinationAccountId: account.id
        )
        do {
            try service.execute(request)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct PSXWithdrawCashView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let account: Account

    @Query private var accounts: [Account]
    @State private var destinationAccount: Account?
    @State private var amount = ""
    @State private var date = Date()
    @State private var showAccountPicker = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Destination Account") {
                    Button(action: { showAccountPicker = true }) {
                        HStack {
                            Text("To")
                            Spacer()
                            if let account = destinationAccount {
                                Text(account.name).foregroundStyle(.primary)
                            } else {
                                Text("Select account").foregroundStyle(.secondary)
                            }
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Amount") {
                    AmountField(amount: $amount)
                    if let amountValue = Decimal(string: amount), amountValue > account.currentBalance {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.yellow)
                            Text("Insufficient cash").font(.caption).foregroundStyle(.red)
                        }
                    }
                }

                Section { DatePicker("Date", selection: $date, displayedComponents: .date) }

                FormErrorSection(message: errorMessage)
            }
            .navigationTitle("Withdraw Cash")
            .formToolbar(label: "Withdraw", isDisabled: destinationAccount == nil || amount.isEmpty) { save() }
            .sheet(isPresented: $showAccountPicker) {
                AccountPickerView(accounts: accounts, title: "Select Destination", filterType: nil) { account in
                    destinationAccount = account
                }
            }
        }
    }

    private func save() {
        guard let dest = destinationAccount else { errorMessage = "Please select a destination account"; return }
        guard let amountValue = Decimal(string: amount), amountValue > 0 else { errorMessage = "Please enter a valid amount"; return }
        guard amountValue <= account.currentBalance else { errorMessage = "Insufficient cash"; return }

        let service = LedgerService(modelContext: modelContext)
        let request = TransactionRequest(
            type: .investmentWithdrawal,
            amount: amountValue,
            date: date,
            description: "Withdraw cash from PSX account",
            sourceAccountId: account.id,
            destinationAccountId: dest.id
        )
        do {
            try service.execute(request)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
