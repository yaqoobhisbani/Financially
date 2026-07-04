import SwiftUI
import SwiftData
import Charts

struct NetWorthChart: View {
    @Environment(\.modelContext) private var modelContext

    @State private var vm: NetWorthViewModel?
    @State private var startDate = Date().startOfYear
    @State private var endDate = Date()
    @State private var selectedPreset = DateRangePickerView.DatePreset.thisYear

    private var dataPoints: [NetWorthViewModel.NetWorthPoint] {
        guard let vm else { return [] }
        return vm.dataPoints(from: startDate, to: endDate)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DateRangePickerView(startDate: $startDate, endDate: $endDate, selectedPreset: $selectedPreset)
                    .padding(.horizontal)
                    .padding(.top, 8)

                List {
                    Section("Net Worth Over Time") {
                        Chart(dataPoints) { point in
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value("Net Worth", point.netWorth)
                            )
                            .foregroundStyle(.blue)
                            .interpolationMethod(.monotone)

                            AreaMark(
                                x: .value("Date", point.date),
                                y: .value("Net Worth", point.netWorth)
                            )
                            .foregroundStyle(.blue.opacity(0.1))
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .month)) { value in
                                AxisValueLabel(format: .dateTime.month(.abbreviated))
                            }
                        }
                        .frame(height: 250)
                    }

                    Section("Current Snapshot") {
                        if let latest = dataPoints.last {
                            LabeledContent("Net Worth", value: latest.netWorth.formattedCurrency())
                            LabeledContent("Total Assets", value: latest.assets.formattedCurrency())
                            LabeledContent("Liabilities Owed", value: latest.liabilities.formattedCurrency())
                        }
                    }
                }
            }
            .navigationTitle("Net Worth Trend")
        }
        .onAppear {
            vm = NetWorthViewModel(modelContext: modelContext)
        }
    }
}