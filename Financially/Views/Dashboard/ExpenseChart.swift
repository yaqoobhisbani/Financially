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

    private func percent(of item: DashboardViewModel.ExpenseBreakdown) -> Decimal {
        total > 0 ? item.total / total * 100 : 0
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
                ForEach(Array(breakdown.prefix(5).enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(CategoryPalette.color(at: index))
                            .frame(width: 8, height: 8)
                        Text(item.category)
                            .font(.caption)
                        Spacer()
                        Text(item.total.formattedCurrency())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(percent(of: item).formatted(.number.precision(.fractionLength(1))))%")
                            .font(.caption2)
                            .tabularNumbers()
                            .foregroundStyle(.tertiary)
                            .frame(minWidth: 42, alignment: .trailing)
                    }
                }
            }
        }
        .padding()
        .dashboardCard()
    }
}
