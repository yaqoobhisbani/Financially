import SwiftUI
import SwiftData

struct InvestmentDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var account: Account

    @Query private var investmentEntries: [InvestmentEntry]
    @State private var showLogPAndL = false
    @State private var showAddCapital = false
    @State private var showWithdraw = false

    init(account: Account) {
        self.account = account
        let accountId = account.id
        _investmentEntries = Query(filter: #Predicate<InvestmentEntry> { $0.investmentAccountId == accountId }, sort: \.date, order: .reverse)
    }

    var body: some View {
        List {
            performanceSection
            actionsSection
            historySection
        }
        .navigationTitle(account.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Log P&L", systemImage: "plus.forwardslash.minus") { showLogPAndL = true }
                    Button("Add Capital", systemImage: "plus.circle") { showAddCapital = true }
                    Button("Withdraw / Sell", systemImage: "arrow.up.right.circle") { showWithdraw = true }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showLogPAndL) {
            LogProfitLossView(account: account)
        }
        .sheet(isPresented: $showAddCapital) {
            AddCapitalView(account: account)
        }
        .sheet(isPresented: $showWithdraw) {
            WithdrawView(account: account)
        }
    }

    private var performanceSection: some View {
        Section("Performance") {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Current Value")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(account.currentValue.formattedCurrency(currency: account.currency))
                            .font(.title.bold())
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Return")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(returnFormatted)
                            .font(.title3.bold())
                            .foregroundStyle(account.totalProfitLoss >= 0 ? .incomeGreen : .expenseRed)
                    }
                }

                Divider()

                HStack {
                    VStack(alignment: .leading) {
                        Text("Invested")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(account.investedAmount.formattedCurrency(currency: account.currency))
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("P&L")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(account.totalProfitLoss.formattedCurrency(currency: account.currency))
                            .foregroundStyle(account.totalProfitLoss >= 0 ? .incomeGreen : .expenseRed)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var actionsSection: some View {
        Section("Actions") {
            Button(action: { showLogPAndL = true }) {
                Label("Log Profit / Loss", systemImage: "plus.forwardslash.minus")
            }
            Button(action: { showAddCapital = true }) {
                Label("Add Capital", systemImage: "plus.circle")
            }
            Button(action: { showWithdraw = true }) {
                Label("Withdraw / Sell", systemImage: "arrow.up.right.circle")
            }
        }
    }

    private var historySection: some View {
        Section("P&L History") {
            ForEach(investmentEntries) { entry in
                HStack {
                    VStack(alignment: .leading) {
                        Text(entry.type == .profit ? "Profit" : "Loss")
                            .font(.headline)
                        Text(entry.date.formattedDate())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(entry.amount.formattedCurrency(currency: account.currency))
                            .foregroundStyle(entry.type == .profit ? .incomeGreen : .expenseRed)
                        if let period = entry.period {
                            Text(period)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if investmentEntries.isEmpty {
                Text("No P&L entries yet")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
    }

    private var returnFormatted: String {
        let percentage = account.returnPercentage
        let formatted = percentage.formatted(.number.precision(.fractionLength(2)))
        return "\(formatted)%"
    }
}