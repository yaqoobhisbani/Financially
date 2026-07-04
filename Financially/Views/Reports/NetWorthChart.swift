import SwiftUI
import SwiftData
import Charts

struct NetWorthChart: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allTransactions: [Transaction]
    @Query private var accounts: [Account]
    @Query private var debtors: [Debtor]
    @Query private var creditors: [Creditor]
    @Query private var commodityHoldings: [CommodityHolding]
    @State private var startDate = Date().startOfYear
    @State private var endDate = Date()
    @State private var selectedPreset = DateRangePickerView.DatePreset.thisYear

    struct NetWorthPoint: Identifiable {
        let id = UUID()
        let date: Date
        let netWorth: Decimal
        let assets: Decimal
        let liabilities: Decimal
    }

    private var dataPoints: [NetWorthPoint] {
        let calendar = Calendar.current
        var points: [NetWorthPoint] = []
        let currentCommodityValue = commodityHoldings.filter { $0.totalGrams > 0 }
            .reduce(0) { $0 + $1.currentValue }
        var current = startDate
        while current <= endDate {
            let monthEnd = calendar.date(byAdding: DateComponents(month: 1, second: -1), to: current) ?? current

            let totalAssets = accounts.filter { $0.isActive }.reduce(0) { sum, acct in
                sum + balanceForAccount(acct, at: monthEnd)
            } + currentCommodityValue

            let totalReceivables = debtors.reduce(0) { sum, debtor in
                sum + debtorOutstanding(debtor, at: monthEnd)
            }

            let totalLiabilities = creditors.reduce(0) { sum, creditor in
                sum + creditorOutstanding(creditor, at: monthEnd)
            }

            let netWorth = totalAssets - totalLiabilities + totalReceivables
            points.append(NetWorthPoint(date: current, netWorth: netWorth, assets: totalAssets, liabilities: totalLiabilities))
            current = calendar.date(byAdding: .month, value: 1, to: current) ?? current
        }
        return points
    }

    private func balanceForAccount(_ account: Account, at date: Date) -> Decimal {
        let allEntries = (try? modelContext.fetch(FetchDescriptor<LedgerEntry>())) ?? []
        let entries = allEntries.filter { $0.accountId == account.id && $0.date <= date }
            .sorted { $0.date > $1.date }
        if let lastEntry = entries.first {
            return lastEntry.runningBalance
        }
        return account.initialBalance
    }

    private func debtorOutstanding(_ debtor: Debtor, at date: Date) -> Decimal {
        let allTxs = (try? modelContext.fetch(FetchDescriptor<Transaction>())) ?? []
        let txs = allTxs.filter { $0.relatedEntityId == debtor.id && $0.date <= date }
        let lent = txs.filter { $0.type == .loanGiven }.reduce(0) { $0 + $1.amount }
        let repaid = txs.filter { $0.type == .loanRepayment }.reduce(0) { $0 + $1.amount }
        return lent - repaid
    }

    private func creditorOutstanding(_ creditor: Creditor, at date: Date) -> Decimal {
        let allTxs = (try? modelContext.fetch(FetchDescriptor<Transaction>())) ?? []
        let txs = allTxs.filter { $0.relatedEntityId == creditor.id && $0.date <= date }
        let received = txs.filter { $0.type == .liabilityReceived }.reduce(0) { $0 + $1.amount }
        let returned = txs.filter { $0.type == .liabilityPayback }.reduce(0) { $0 + $1.amount }
        return received - returned
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DateRangePickerView(startDate: $startDate, endDate: $endDate, selectedPreset: $selectedPreset)

                List {
                    Section("Net Worth Over Time") {
                        Chart(dataPoints) { point in
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value("Net Worth", point.netWorth)
                            )
                            .foregroundStyle(.blue)
                            .interpolationMethod(.monotone)

                            AreaMark(
                                x: .value("Date", point.date),
                                y: .value("Net Worth", point.netWorth)
                            )
                            .foregroundStyle(.blue.opacity(0.1))
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .month)) { value in
                                AxisValueLabel(format: .dateTime.month(.abbreviated))
                            }
                        }
                        .frame(height: 250)
                    }

                    Section("Current Snapshot") {
                        if let latest = dataPoints.last {
                            LabeledContent("Net Worth", value: latest.netWorth.formattedCurrency())
                            LabeledContent("Total Assets", value: latest.assets.formattedCurrency())
                            LabeledContent("Liabilities Owed", value: latest.liabilities.formattedCurrency())
                        }
                    }
                }
            }
            .navigationTitle("Net Worth Trend")
        }
    }
}