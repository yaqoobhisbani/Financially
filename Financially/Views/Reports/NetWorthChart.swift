import SwiftUI
import SwiftData
import Charts

struct NetWorthChart: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager

    @State private var vm: NetWorthViewModel?
    @State private var startDate = Date().startOfYear
    @State private var endDate = Date()
    @State private var selectedPreset = DateRangePickerView.DatePreset.thisYear

    private var dataPoints: [NetWorthViewModel.NetWorthPoint] {
        guard let vm else { return [] }
        return vm.dataPoints(from: startDate, to: endDate)
    }

    private var latest: NetWorthViewModel.NetWorthPoint? { dataPoints.last }
    private var change: Decimal {
        guard let first = dataPoints.first, let latest else { return 0 }
        return latest.netWorth - first.netWorth
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DateRangePickerView(startDate: $startDate, endDate: $endDate, selectedPreset: $selectedPreset)
                    .padding(.horizontal)
                    .padding(.top, 8)

                canvas
            }
            .groupedScreenBackground()
            .persistentGlassSheet(
                isPresented: .constant(true),
                detents: [.height(130), .medium, .large],
                interactiveUpThrough: .medium,
                dismissible: false
            ) {
                breakdownSheet
            }
            .navigationTitle("Net Worth Trend")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            vm = NetWorthViewModel(modelContext: modelContext)
        }
    }

    // MARK: - Chart Canvas

    private var canvas: some View {
        VStack(alignment: .leading, spacing: 4) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Net Worth")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text((latest?.netWorth ?? 0).formattedCurrency())
                    .font(.moneyHero)
                    .tabularNumbers()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                HStack(spacing: 4) {
                    Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                    Text(change.formattedCurrency())
                    Text("over selected range")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline.weight(.medium))
                .tabularNumbers()
                .foregroundStyle(change >= 0 ? .gain : .loss)
            }
            .padding(.horizontal)
            .padding(.top, 12)

            if dataPoints.isEmpty {
                Spacer()
                Text("No data for this range")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                Chart(dataPoints) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Net Worth", point.netWorth)
                    )
                    .foregroundStyle(themeManager.theme.accent)
                    .interpolationMethod(.monotone)

                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Net Worth", point.netWorth)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [themeManager.theme.accent.opacity(0.28), themeManager.theme.accent.opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.monotone)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { _ in
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
                .padding(.horizontal)
                .padding(.bottom, 140)
                .frame(maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Breakdown Sheet

    private var breakdownSheet: some View {
        NavigationStack {
            List {
                Section("Current Snapshot") {
                    breakdownRow(label: "Net Worth", value: latest?.netWorth ?? 0, icon: "heart.fill", tint: themeManager.theme.accent)
                    breakdownRow(label: "Total Assets", value: latest?.assets ?? 0, icon: "building.columns.fill", tint: .gain)
                    breakdownRow(label: "Receivables", value: latest?.receivables ?? 0, icon: "arrow.left.circle.fill", tint: themeManager.theme.accent)
                    breakdownRow(label: "Liabilities Owed", value: latest?.liabilities ?? 0, icon: "arrow.right.circle.fill", tint: .loss)
                }
            }
            .navigationTitle("Breakdown")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func breakdownRow(label: String, value: Decimal, icon: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)
                .background(tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

            Text(label)
                .font(.body)

            Spacer()

            Text(value.formattedCurrency())
                .font(.body.weight(.semibold))
                .tabularNumbers()
        }
    }
}
