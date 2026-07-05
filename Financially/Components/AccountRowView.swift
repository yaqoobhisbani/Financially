import SwiftUI

struct AccountRowView: View {
    let account: Account
    let holdings: [StockHolding]

    private var displayBalance: Decimal {
        account.accountType == .psx ? account.currentBalance + (holdings.filter { $0.accountId == account.id }.reduce(0) { $0 + $1.currentValue }) : account.currentBalance
    }

    var body: some View {
        HStack(spacing: 12) {
            if account.accountType == .bank, let bankName = account.bankName {
                BankLogoView(bankName: bankName, size: 40)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(accountColor.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: accountIcon)
                        .foregroundStyle(accountColor)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(.headline)
                    .lineLimit(1)
                Text(accountSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(displayBalance.formattedCurrency(currency: account.currency))
                .font(.headline)
                .fixedSize(horizontal: true, vertical: false)
        }
        .opacity(account.isActive ? 1 : 0.5)
    }

    private var accountIcon: String {
        account.icon ?? defaultIcon
    }

    private var defaultIcon: String {
        switch account.accountType {
        case .bank: return "building.columns.fill"
        case .cash: return "wallet.pass.fill"
        case .psx: return "chart.line.uptrend.xyaxis"
        }
    }

    private var accountColor: Color {
        if let hex = account.color {
            return Color(hex: hex) ?? tintColor
        }
        return tintColor
    }

    private var tintColor: Color {
        switch account.accountType {
        case .bank: return .accountBank
        case .cash: return .accountCash
        case .psx: return .accountPSX
        }
    }

    private var accountSubtitle: String {
        switch account.accountType {
        case .bank:
            return account.bankName ?? "Bank Account"
        case .cash:
            return account.cashSubType?.rawValue.capitalized ?? "Cash"
        case .psx:
            return account.brokerName ?? "PSX Account"
        }
    }
}

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        guard hex.count == 6, let value = UInt64(hex, radix: 16) else { return nil }
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}