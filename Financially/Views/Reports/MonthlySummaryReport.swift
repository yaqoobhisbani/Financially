import SwiftUI
import SwiftData
import Charts

struct MonthlySummaryReport: View {
    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]
    @State private var selectedMonth = Date()

    private var monthTransactions: [Transaction] {
        allTransactions.filter { tx in
            Calendar.current.isDate(tx.date, equalTo: selectedMonth, toGranularity: .month)
        }
    }

    private var income: Decimal { monthTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount } }
    private var expense: Decimal { monthTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount } }
    private var netSavings: Decimal { income - expense }

    private var expenseByCategory: [(category: String, total: Decimal)] {
        let grouped = Dictionary(grouping: monthTransactions.filter { $0.type == .expense }) { $0.category ?? "Other" }
        return grouped.map { ($0.key, $0.value.reduce(0) { $0 + $1.amount }) }.sorted { $0.total > $1.total }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Button(action: { selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth }) {
                        Image(systemName: "chevron.left")
                    }
                    Text(selectedMonth.monthYear())
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                    Button(action: { selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth }) {
                        Image(systemName: "chevron.right")
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                List {
                    Section("Summary") {
                        HStack {
                            Text("Income")
                            Spacer()
                            Text(income.formattedCurrency()).foregroundStyle(.incomeGreen)
                        }
                        HStack {
                            Text("Expenses")
                            Spacer()
                            Text(expense.formattedCurrency()).foregroundStyle(.expenseRed)
                        }
                        HStack {
                            Text("Net")
                            Spacer()
                            Text(netSavings.formattedCurrency())
                                .foregroundStyle(netSavings >= 0 ? .incomeGreen : .expenseRed)
                        }
                    }

                    if !expenseByCategory.isEmpty {
                        Section("Expense Breakdown") {
                            Chart(expenseByCategory, id: \.category) { item in
                                SectorMark(angle: .value("Amount", item.total), innerRadius: .ratio(0.6))
                                    .foregroundStyle(by: .value("Category", item.category))
                            }
                            .frame(height: 180)
                        }
                    }

                    Section("Transactions (\(monthTransactions.count))") {
                        ForEach(monthTransactions) { tx in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(tx.type.displayLabel)
                                        .font(.headline)
                                    Text(tx.date.formattedDate())
                                        .font(.caption)
                                }
                                Spacer()
                                Text(tx.amount.formattedCurrency())
                                    .foregroundStyle(tx.type == .income ? .incomeGreen : .expenseRed)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Monthly Summary")
        }
    }
}