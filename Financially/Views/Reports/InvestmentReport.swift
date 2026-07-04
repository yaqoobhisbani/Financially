import SwiftUI
import SwiftData

struct InvestmentReport: View {
    @Query private var accounts: [Account]
    @Query(sort: \InvestmentEntry.date, order: .reverse) private var investmentEntries: [InvestmentEntry]
    @State private var startDate = Date().startOfMonth
    @State private var endDate = Date()
    @State private var selectedPreset = DateRangePickerView.DatePreset.thisMonth

    private var investmentAccounts: [Account] {
        accounts.filter { $0.accountType == .psx }
    }

    private func entries(for account: Account) -> [InvestmentEntry] {
        investmentEntries.filter { $0.investmentAccountId == account.id && $0.date >= startDate && $0.date <= endDate.endOfDay }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DateRangePickerView(startDate: $startDate, endDate: $endDate, selectedPreset: $selectedPreset)

                List {
                    Section {
                        HStack {
                            Text("Total Investment Value")
                            Spacer()
                            Text(investmentAccounts.reduce(0) { $0 + $1.currentValue }.formattedCurrency())
                                .font(.headline)
                        }
                        HStack {
                            Text("Total Invested")
                            Spacer()
                            Text(investmentAccounts.reduce(0) { $0 + $1.investedAmount }.formattedCurrency())
                        }
                        HStack {
                            Text("Total P&L")
                            Spacer()
                            Text(investmentAccounts.reduce(0) { $0 + $1.totalProfitLoss }.formattedCurrency())
                                .foregroundStyle(investmentAccounts.reduce(0) { $0 + $1.totalProfitLoss } >= 0 ? .incomeGreen : .expenseRed)
                        }
                    }

                    ForEach(investmentAccounts) { account in
                        Section(account.name) {
                            let entries = entries(for: account)
                            if entries.isEmpty {
                                Text("No entries in this period")
                                    .foregroundStyle(.secondary)
                            }
                            ForEach(entries) { entry in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(entry.type == .profit ? "Profit" : "Loss")
                                            .font(.headline)
                                        Text(entry.date.formattedDate())
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(entry.amount.formattedCurrency())
                                        .foregroundStyle(entry.type == .profit ? .incomeGreen : .expenseRed)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Investment Report")
        }
    }
}