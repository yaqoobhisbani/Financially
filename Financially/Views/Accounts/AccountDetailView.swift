import SwiftUI
import SwiftData

struct AccountDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let account: Account

    @Query(sort: \LedgerEntry.date, order: .reverse) private var allLedgerEntries: [LedgerEntry]
    @Query private var allTransactions: [Transaction]
    @Query private var allHoldings: [StockHolding]
    @State private var showStatement = false
    @State private var showEdit = false
    @State private var selectedTransaction: Transaction?
    @State private var showBuy = false
    @State private var showSell = false
    @State private var showAddCash = false
    @State private var showWithdraw = false

    private var ledgerEntries: [LedgerEntry] {
        allLedgerEntries.filter { $0.accountId == account.id }
    }

    private var accountHoldings: [StockHolding] {
        allHoldings.filter { $0.accountId == account.id && $0.totalShares > 0 }
    }

    private var totalHoldingValue: Decimal {
        accountHoldings.reduce(0) { $0 + $1.currentValue }
    }

    private var totalCostBasis: Decimal {
        accountHoldings.reduce(0) { $0 + $1.totalCost }
    }

    private var totalUnrealizedPAndL: Decimal {
        accountHoldings.reduce(0) { $0 + $1.unrealizedPAndL }
    }

    private var totalPAndLPercentage: Decimal {
        guard totalCostBasis > 0 else { return 0 }
        return (totalUnrealizedPAndL / totalCostBasis) * 100
    }

    var body: some View {
        List {
            balanceSection
            if account.accountType == .psx {
                psxActionsSection
                psxHoldingsSection
            }
            if account.accountType == .mutualFund {
                investmentSection
            }
recentTransactionsSection
            accountInfoSection
        }
        .navigationTitle(account.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("View Statement", systemImage: "doc.text") { showStatement = true }
                    Button("Edit Account", systemImage: "pencil") { showEdit = true }
                    Button(account.isActive ? "Deactivate" : "Activate", systemImage: account.isActive ? "eye.slash" : "eye") {
                        account.isActive.toggle()
                        account.updatedAt = Date()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showStatement) {
            AccountStatementView(account: account)
        }
        .sheet(isPresented: $showEdit) {
            EditAccountView(account: account)
        }
        .sheet(isPresented: $showBuy) { BuySharesView(account: account) }
        .sheet(isPresented: $showSell) { SellSharesView(account: account) }
        .sheet(isPresented: $showAddCash) { PSXAddCashView(account: account) }
        .sheet(isPresented: $showWithdraw) { PSXWithdrawCashView(account: account) }
    }

    private var balanceSection: some View {
        Section {
            VStack(spacing: 8) {
                if account.accountType == .psx {
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Total Portfolio")
                                    .font(.caption).foregroundStyle(.secondary)
                                Text((account.currentBalance + totalHoldingValue).formattedCurrency(currency: account.currency))
                                    .font(.title.bold())
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("P&L")
                                    .font(.caption).foregroundStyle(.secondary)
                                Text(totalUnrealizedPAndL.formattedCurrency(currency: account.currency))
                                    .font(.title3.bold())
                                    .foregroundStyle(totalUnrealizedPAndL >= 0 ? .incomeGreen : .expenseRed)
                            }
                        }

                        Divider()

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Available Cash")
                                    .font(.caption).foregroundStyle(.secondary)
                                Text(account.currentBalance.formattedCurrency(currency: account.currency))
                                    .font(.body.bold())
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("Holdings Value")
                                    .font(.caption).foregroundStyle(.secondary)
                                Text(totalHoldingValue.formattedCurrency(currency: account.currency))
                                    .font(.body.bold())
                                    .foregroundStyle(.incomeGreen)
                            }
                        }

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Total Cost")
                                    .font(.caption).foregroundStyle(.secondary)
                                Text(totalCostBasis.formattedCurrency(currency: account.currency))
                                    .font(.body.bold())
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("Return")
                                    .font(.caption).foregroundStyle(.secondary)
                                Text(totalPAndLPercentage.formatted(.number.precision(.fractionLength(2))) + "%")
                                    .font(.body.bold())
                                    .foregroundStyle(totalUnrealizedPAndL >= 0 ? .incomeGreen : .expenseRed)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                } else if account.accountType == .mutualFund {
                    HStack {
                        Text("Invested")
                        Spacer()
                        Text(account.investedAmount.formattedCurrency(currency: account.currency))
                    }
                    HStack {
                        Text("P/L")
                        Spacer()
                        Text(account.totalProfitLoss.formattedCurrency(currency: account.currency))
                            .foregroundStyle(account.totalProfitLoss >= 0 ? .incomeGreen : .expenseRed)
                    }
                    HStack {
                        Text("Current Value")
                            .font(.headline)
                        Spacer()
                        Text(account.currentValue.formattedCurrency(currency: account.currency))
                            .font(.headline)
                    }
                    HStack {
                        Text("Return")
                        Spacer()
                        Text("\(account.returnPercentage)")
                            .foregroundStyle(account.returnPercentage >= 0 ? .incomeGreen : .expenseRed)
                    }
                } else {
                    Text(account.currentBalance.formattedCurrency(currency: account.currency))
                        .font(.largeTitle.bold())
                    Text(account.initialBalance == account.currentBalance ? "Initial balance" : "From initial \(account.initialBalance.formattedCurrency(currency: account.currency))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var accountInfoSection: some View {
        Section("Info") {
            infoRow("Type", value: accountTypeLabel)
            if account.accountType == .bank {
                if let bank = account.bankName {
                    infoRow("Bank", value: bank)
                }
                if let num = account.accountNumber { infoRow("Account #", value: num) }
            }
            if account.accountType == .cash, let sub = account.cashSubType {
                infoRow("Sub Type", value: sub.rawValue.capitalized)
            }
            if account.accountType == .psx, let broker = account.brokerName {
                infoRow("Broker", value: broker)
            }
            if account.accountType == .mutualFund, let house = account.fundHouse {
                infoRow("Fund House", value: house)
            }
            infoRow("Currency", value: account.currency)
            infoRow("Status", value: account.isActive ? "Active" : "Inactive")
            if let notes = account.notes, !notes.isEmpty {
                infoRow("Notes", value: notes)
            }
        }
    }

    private func infoRow(_ label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 72, alignment: .leading)
            Text(value)
                .font(.subheadline)
            Spacer()
        }
        .padding(.vertical, 2)
    }

    private var psxActionsSection: some View {
        Section {
            HStack(spacing: 10) {
                actionCard("Buy", icon: "plus.circle.fill", color: .incomeGreen) { showBuy = true }
                actionCard("Sell", icon: "minus.circle.fill", color: .expenseRed) { showSell = true }
                actionCard("Add Cash", icon: "arrow.down.circle.fill", color: .blue) { showAddCash = true }
                actionCard("Withdraw", icon: "arrow.up.circle.fill", color: .orange) { showWithdraw = true }
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        } header: {
            Text("Actions")
        }
    }

    private func actionCard(_ label: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                Text(label)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 4)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var psxHoldingsSection: some View {
        Section("Holdings") {
            if accountHoldings.isEmpty {
                Text("No holdings yet. Buy shares to get started.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
            ForEach(accountHoldings) { holding in
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

    private var investmentSection: some View {
        EmptyView()
    }

    private var recentTransactionsSection: some View {
        Section("Recent Transactions") {
            ForEach(Array(ledgerEntries.prefix(20))) { entry in
                LedgerRowView(entry: entry, currency: account.currency)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedTransaction = allTransactions.first { $0.id == entry.transactionId }
                    }
            }

            if ledgerEntries.isEmpty {
                Text("No transactions yet")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .sheet(item: $selectedTransaction) { tx in
            NavigationStack {
                TransactionDetailView(transaction: tx)
            }
        }
    }

    private var accountTypeLabel: String {
        switch account.accountType {
        case .bank: return "Bank Account"
        case .cash: return "Cash"
        case .psx: return "PSX Stock Account"
        case .mutualFund: return "Mutual Fund Account"
        }
    }
}

struct PSXAddCashView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let account: Account

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
                    HStack {
                        Text("PKR")
                        TextField("0", text: $amount).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    }
                }

                Section { DatePicker("Date", selection: $date, displayedComponents: .date) }

                if let errorMessage = errorMessage {
                    Section { Text(errorMessage).foregroundStyle(.red) }
                }
            }
            .navigationTitle("Add Cash")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }.disabled(sourceAccount == nil || amount.isEmpty)
                }
            }
            .sheet(isPresented: $showAccountPicker) {
                AccountPickerView(title: "Select Source", filterType: nil) { account in
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
                    HStack {
                        Text("PKR")
                        TextField("0", text: $amount).keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    }
                    if let amountValue = Decimal(string: amount), amountValue > account.currentBalance {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.yellow)
                            Text("Insufficient cash").font(.caption).foregroundStyle(.red)
                        }
                    }
                }

                Section { DatePicker("Date", selection: $date, displayedComponents: .date) }

                if let errorMessage = errorMessage {
                    Section { Text(errorMessage).foregroundStyle(.red) }
                }
            }
            .navigationTitle("Withdraw Cash")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Withdraw") { save() }.disabled(destinationAccount == nil || amount.isEmpty)
                }
            }
            .sheet(isPresented: $showAccountPicker) {
                AccountPickerView(title: "Select Destination", filterType: nil) { account in
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