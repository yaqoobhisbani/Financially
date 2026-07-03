import SwiftUI
import Charts

struct BarChartView: View {
    let data: [DashboardViewModel.MonthlyComparison]

    var body: some View {
        if data.isEmpty {
            Text("No data")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        } else {
            Chart {
                ForEach(data) { item in
                    BarMark(
                        x: .value("Month", item.month, unit: .month),
                        y: .value("Income", item.income)
                    )
                    .foregroundStyle(.incomeGreen)
                    .position(by: .value("Type", "Income"))

                    BarMark(
                        x: .value("Month", item.month, unit: .month),
                        y: .value("Expense", item.expense)
                    )
                    .foregroundStyle(.expenseRed)
                    .position(by: .value("Type", "Expense"))
                }
            }
            .chartForegroundStyleScale([
                "Income": Color.incomeGreen,
                "Expense": Color.expenseRed,
            ])
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { value in
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                }
            }
            .frame(height: 200)
        }
    }
}