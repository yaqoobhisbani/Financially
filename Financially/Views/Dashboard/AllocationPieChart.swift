import SwiftUI
import Charts

struct AllocationPieChart: View {
    let slices: [DashboardViewModel.AllocationSlice]

    private var total: Decimal {
        slices.reduce(0) { $0 + $1.value }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Allocation")
                .font(.headline)

            if total > 0 {
                Chart(slices) { slice in
                    SectorMark(
                        angle: .value("Value", NSDecimalNumber(decimal: slice.value).doubleValue),
                        innerRadius: .ratio(0.6),
                        outerRadius: .ratio(0.95)
                    )
                    .foregroundStyle(by: .value("Label", slice.label))
                    .cornerRadius(4)
                }
                .chartForegroundStyleScale(domain: slices.map(\.label)) { label in
                    color(for: label)
                }
                .chartLegend(.hidden)
                .frame(height: 240)

                legend
            } else {
                Text("No assets to display")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            }
        }
        .padding()
        .dataCard()
    }

    private var legend: some View {
        VStack(spacing: 8) {
            ForEach(slices) { slice in
                HStack(spacing: 10) {
                    Circle()
                        .fill(color(for: slice.label))
                        .frame(width: 10, height: 10)
                    Text(slice.label)
                        .font(.subheadline)
                    Spacer()
                    Text(slice.value.formattedCurrency())
                        .font(.subheadline)
                    Text("(\(percentage(slice.value)))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func percentage(_ value: Decimal) -> String {
        guard total > 0 else { return "0%" }
        let pct = NSDecimalNumber(decimal: value / total * 100).doubleValue
        return "\(Int(pct.rounded()))%"
    }

    private func color(for label: String) -> Color {
        switch label {
        case "PSX": return .blue
        case "Commodities": return .orange
        case "Banks": return .green
        case "Cash": return .mint
        case "Receivable": return .purple
        case "Committee": return .teal
        case "Liabilities": return .red
        default: return .gray
        }
    }
}