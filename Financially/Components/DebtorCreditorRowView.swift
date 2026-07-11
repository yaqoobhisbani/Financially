import SwiftUI

struct DebtorCreditorRowView: View {
    let name: String
    let phone: String?
    let email: String?
    let outstandingBalance: Decimal
    let balanceColor: Color
    let isSettled: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.fill")
                .font(.title3)
                .foregroundStyle(balanceColor)
                .frame(width: 40, height: 40)
                .background(balanceColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.headline)
                    .lineLimit(1)
                if let phone {
                    Text(phone)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if let email {
                    Text(email)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(outstandingBalance.formattedCurrency())
                    .font(.headline)
                    .tabularNumbers()
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
