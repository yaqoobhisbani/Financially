import SwiftUI
import SwiftData
import Charts

struct NetWorthChart: View {
    @Query private var allTransactions: [Transaction]
    @Query private var accounts: [Account]
    @Query private var debtors: [Debtor]
    @Query private var creditors: [Creditor]
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
        var current = startDate
        while current <= endDate {
            let monthTxs = accounts.filter { $0.isActive }
            let totalAssets = monthTxs.reduce(0) { sum, acct in
                sum + (acct.accountType == .psx ? acct.currentValue : acct.currentBalance)
            }
            let totalLiabilities = creditors.reduce(0) { $0 + $1.outstandingBalance }
            let totalReceivables = debtors.reduce(0) { $0 + $1.outstandingBalance }
            let netWorth = totalAssets - totalLiabilities + totalReceivables

            points.append(NetWorthPoint(date: current, netWorth: netWorth, assets: totalAssets, liabilities: totalLiabilities))
            current = calendar.date(byAdding: .month, value: 1, to: current) ?? current
        }
        return points
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