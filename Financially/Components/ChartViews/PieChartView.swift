import SwiftUI
import Charts

/// Shared categorical palette so pie slices and their matching list rows use the
/// same color, addressed by position in the (sorted) breakdown.
enum CategoryPalette {
    static let colors: [Color] = [.blue, .green, .orange, .purple, .red, .teal, .pink, .indigo, .mint, .cyan]

    static func color(at index: Int) -> Color {
        colors[index % colors.count]
    }
}

struct PieChartView: View {
    let data: [DashboardViewModel.ExpenseBreakdown]
    let total: Decimal

    var body: some View {
        if data.isEmpty {
            Text("No data this month")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        } else {
            Chart {
                ForEach(Array(data.enumerated()), id: \.element.id) { index, item in
                    SectorMark(
                        angle: .value("Amount", item.total),
                        innerRadius: .ratio(0.6)
                    )
                    .foregroundStyle(CategoryPalette.color(at: index))
                }
            }
            .chartLegend(.hidden)
            .frame(height: 200)
        }
    }
}
