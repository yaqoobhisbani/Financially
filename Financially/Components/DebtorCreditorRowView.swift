import SwiftUI

struct DebtorCreditorRowView: View {
    let name: String
    let phone: String?
    let email: String?
    let outstandingBalance: Decimal
    let balanceColor: Color
    let isSettled: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(name)
                    .font(.headline)
                if let phone {
                    Text(phone)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let email {
                    Text(email)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(outstandingBalance.formattedCurrency())
                    .font(.headline)
                    .foregroundStyle(outstandingBalance > 0 ? balanceColor : .secondary)
                if isSettled {
                    Text("Settled")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .opacity(isSettled ? 0.6 : 1)
    }
}
