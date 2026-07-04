import SwiftUI
import SwiftData

struct IncomeReport: View {
    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]
    @State private var startDate = Date().startOfMonth
    @State private var endDate = Date()
    @State private var selectedPreset = DateRangePickerView.DatePreset.thisMonth

    private var incomes: [Transaction] {
        allTransactions.filter { $0.type == .income && $0.date >= startDate && $0.date <= endDate.endOfDay }
    }

    private var totalIncome: Decimal {
        incomes.reduce(0) { $0 + $1.amount }
    }

    private var byCategory: [(category: String, total: Decimal)] {
        let grouped = Dictionary(grouping: incomes) { $0.category ?? "Other" }
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
                            Text("Total Income")
                            Spacer()
                            Text(totalIncome.formattedCurrency())
                                .font(.title3.bold())
                                .foregroundStyle(.incomeGreen)
                        }
                    }

                    Section("By Source") {
                        ForEach(byCategory, id: \.category) { item in
                            HStack {
                                Text(item.category)
                                Spacer()
                                Text(item.total.formattedCurrency())
                            }
                        }
                    }

                    if byCategory.isEmpty {
                        ContentUnavailableView("No Income", systemImage: "arrow.down.circle", description: Text("No income found in this period"))
                    }

                    Section("All Transactions") {
                        ForEach(incomes) { tx in
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
                                    .foregroundStyle(.incomeGreen)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Income Report")
        }
    }
}