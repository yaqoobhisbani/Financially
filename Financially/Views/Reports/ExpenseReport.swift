import SwiftUI
import SwiftData

struct ExpenseReport: View {
    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]
    @State private var startDate = Date().startOfMonth
    @State private var endDate = Date()
    @State private var selectedPreset = DateRangePickerView.DatePreset.thisMonth

    private var expenses: [Transaction] {
        allTransactions.filter { $0.type == .expense && $0.date >= startDate && $0.date <= endDate.endOfDay }
    }

    private var totalExpense: Decimal {
        expenses.reduce(0) { $0 + $1.amount }
    }

    private var byCategory: [(category: String, total: Decimal)] {
        let grouped = Dictionary(grouping: expenses) { $0.category ?? "Other" }
        return grouped.map { ($0.key, $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.total > $1.total }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DateRangePickerView(startDate: $startDate, endDate: $endDate, selectedPreset: $selectedPreset)

                List {
                    Section {
                        HStack {
                            Text("Total Expenses")
                            Spacer()
                            Text(totalExpense.formattedCurrency())
                                .bold()
                        }
                    }

                    Section("By Category") {
                        ForEach(byCategory, id: \.category) { item in
                            HStack {
                                Text(item.category)
                                Spacer()
                                Text(item.total.formattedCurrency())
                            }
                        }
                    }

                    if byCategory.isEmpty {
                        ContentUnavailableView("No Expenses", systemImage: "arrow.up.circle", description: Text("No expenses found in this period"))
                    }

                    Section("All Transactions") {
                        ForEach(expenses) { tx in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(tx.category ?? "Other")
                                        .font(.headline)
                                    Text(tx.date.formattedDate())
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(tx.amount.formattedCurrency())
                                    .foregroundStyle(.expenseRed)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Expense Report")
        }
    }
}