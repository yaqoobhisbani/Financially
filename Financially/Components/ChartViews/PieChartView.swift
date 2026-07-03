import SwiftUI
import Charts

struct PieChartView: View {
    let data: [DashboardViewModel.ExpenseBreakdown]
    let total: Decimal

    var body: some View {
        if data.isEmpty {
            Text("No expenses this month")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        } else {
            Chart(data) { item in
                SectorMark(
                    angle: .value("Amount", item.total),
                    innerRadius: .ratio(0.6)
                )
                .foregroundStyle(by: .value("Category", item.category))
            }
            .chartLegend(position: .bottom, spacing: 8)
            .frame(height: 200)
        }
    }
}