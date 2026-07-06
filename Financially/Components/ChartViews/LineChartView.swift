import SwiftUI
import Charts

struct InvestmentLineChartView: View {
    struct DataPoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Decimal
    }

    let dataPoints: [DataPoint]

    var body: some View {
        if dataPoints.isEmpty {
            Text("No investment data")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        } else {
            Chart(dataPoints) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(.blue)
                .interpolationMethod(.monotone)

                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(.blue.opacity(0.1))
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { value in
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let d = value.as(Decimal.self) {
                            Text(d.formatted(.number.notation(.compactName)))
                        }
                    }
                }
            }
            .frame(height: 200)
        }
    }
}