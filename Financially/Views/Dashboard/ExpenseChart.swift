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

    private func percentage(_ value: Decimal) -> String {
        guard total > 0 else { return "0%" }
        let pct = NSDecimalNumber(decimal: value / total * 100).doubleValue
        return "\(Int(pct.rounded()))%"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
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
                VStack(spacing: 8) {
                    ForEach(Array(breakdown.prefix(5).enumerated()), id: \.element.id) { index, item in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(CategoryPalette.color(at: index))
                                .frame(width: 10, height: 10)
                            Text(item.category)
                                .font(.subheadline)
                            Spacer()
                            Text(item.total.formattedCurrency())
                                .font(.subheadline)
                            Text("(\(percentage(item.total)))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .dashboardCard()
    }
}
