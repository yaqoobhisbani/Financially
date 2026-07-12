import SwiftUI

struct ExpenseChartWidget: View {
    let expenseByCategory: [DashboardViewModel.ExpenseBreakdown]
    let totalExpense: Decimal
    let incomeByCategory: [DashboardViewModel.ExpenseBreakdown]
    let totalIncome: Decimal

    private enum Flow: String, CaseIterable {
        case expense = "Expense"
        case income = "Income"
    }

    @State private var flow: Flow = .expense

    private var breakdown: [DashboardViewModel.ExpenseBreakdown] {
        flow == .expense ? expenseByCategory : incomeByCategory
    }

    private var total: Decimal {
        flow == .expense ? totalExpense : totalIncome
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(flow.rawValue) Breakdown")
                    .font(.headline)
                Spacer()
                Text(total.formattedCurrency())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Only offer the toggle when there's income to switch to.
            if !incomeByCategory.isEmpty {
                Picker("Flow", selection: $flow) {
                    ForEach(Flow.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
            }

            PieChartView(data: breakdown, total: total)

            if !breakdown.isEmpty {
                ForEach(breakdown.prefix(5)) { item in
                    HStack {
                        Text(item.category)
                            .font(.caption)
                        Spacer()
                        Text(item.total.formattedCurrency())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .dashboardCard()
    }
}
