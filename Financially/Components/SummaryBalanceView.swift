import SwiftUI

struct SummaryMetric: View {
    let label: String
    let value: String
    var color: Color = .primary
    var valueFont: Font = .body.bold()
    var alignment: HorizontalAlignment = .leading

    var body: some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(valueFont)
                .foregroundStyle(color)
        }
    }
}

struct SummaryMetricView<Content: View>: View {
    let label: String
    var alignment: HorizontalAlignment = .leading
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            content
        }
    }
}

struct SummaryBalanceView: View {
    let heroLeftLabel: String
    let heroLeftValue: String
    var heroLeftFont: Font = .title.bold()
    var heroRightLabel: String? = nil
    var heroRightValue: String? = nil
    var heroRightColor: Color = .primary
    var heroRightFont: Font = .title3.bold()
    var detailRows: [[AnyView]] = []

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                SummaryMetric(label: heroLeftLabel, value: heroLeftValue, valueFont: heroLeftFont)
                Spacer()
                if let heroRightLabel, let heroRightValue {
                    SummaryMetric(label: heroRightLabel, value: heroRightValue, color: heroRightColor, valueFont: heroRightFont, alignment: .trailing)
                }
            }

            Divider()

            ForEach(detailRows.indices, id: \.self) { rowIndex in
                HStack(alignment: .top, spacing: 16) {
                    ForEach(detailRows[rowIndex].indices, id: \.self) { metricIndex in
                        if metricIndex > 0 { Spacer(minLength: 8) }
                        detailRows[rowIndex][metricIndex]
                    }
                    if detailRows[rowIndex].count == 1 {
                        Spacer()
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}
