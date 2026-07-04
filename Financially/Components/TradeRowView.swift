import SwiftUI

struct TradeRowView: View {
    let type: TradeType
    let detail: String
    let date: Date
    let netAmount: String
    let fee: Decimal?
    var currency: String = "PKR"

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Text(type == .buy ? "Buy" : "Sell")
                        .font(.headline)
                        .foregroundStyle(type == .buy ? .incomeGreen : .expenseRed)
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Text(date.formattedDate())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(netAmount)
                    .font(.subheadline.bold())
                if let fee, fee > 0 {
                    Text("Fee: \(fee.formattedCurrency(currency: currency))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
