import SwiftUI

struct ExpenseChartWidget: View {
    let expenseByCategory: [DashboardViewModel.ExpenseBreakdown]
    let totalExpense: Decimal

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Expense Breakdown")
                    .font(.headline)
                Spacer()
                Text(totalExpense.formattedCurrency())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            PieChartView(data: expenseByCategory, total: totalExpense)

            if !expenseByCategory.isEmpty {
                ForEach(expenseByCategory.prefix(5)) { item in
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
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}