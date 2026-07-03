import SwiftUI
import SwiftData

struct AccountsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var accounts: [Account]
    @Query private var allHoldings: [StockHolding]
    @State private var selectedSegment: AccountSegment = .all
    @State private var showCreateSheet = false

    private enum AccountSegment: String, CaseIterable {
        case all = "All"
        case bank = "Bank"
        case cash = "Cash"
        case psx = "PSX"
        case mutualFund = "MF"
    }

    private var filteredAccounts: [Account] {
        switch selectedSegment {
        case .all: return accounts
        case .bank: return accounts.filter { $0.accountType == .bank }
        case .cash: return accounts.filter { $0.accountType == .cash }
        case .psx: return accounts.filter { $0.accountType == .psx }
        case .mutualFund: return accounts.filter { $0.accountType == .mutualFund }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Account Type", selection: $selectedSegment) {
                    ForEach(AccountSegment.allCases, id: \.self) { segment in
                        Text(segment.rawValue).tag(segment)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                List {
                    ForEach(filteredAccounts) { account in
                        NavigationLink(destination: AccountDetailView(account: account)) {
                            AccountRowView(account: account, holdings: allHoldings)
                        }
                    }
                }
                #if os(iOS)
                .listStyle(.insetGrouped)
                #else
                .listStyle(.plain)
                #endif
            }
            .navigationTitle("Accounts")
            .toolbar {
                ToolbarItem {
                    Button(action: { showCreateSheet = true }) {
                        Label("Add Account", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                CreateAccountView()
            }
        }
    }
}

struct AccountRowView: View {
    let account: Account
    let holdings: [StockHolding]

    private var psxHoldings: [StockHolding] {
        holdings.filter { $0.accountId == account.id }
    }

    private var psxPortfolioValue: Decimal {
        psxHoldings.reduce(0) { $0 + $1.currentValue }
    }

    private var psxTotalCost: Decimal {
        psxHoldings.reduce(0) { $0 + $1.totalCost }
    }

    private var psxProfitLoss: Decimal {
        psxPortfolioValue - psxTotalCost
    }

    private var displayBalance: Decimal {
        account.accountType == .psx ? psxPortfolioValue : account.currentBalance
    }

    private var pnlValue: Decimal {
        account.accountType == .psx ? psxProfitLoss : account.totalProfitLoss
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
                Text(accountSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(displayBalance.formattedCurrency(currency: account.currency))
                    .font(.headline)
                if account.accountType == .psx || account.accountType == .mutualFund {
                    Text(pnlValue.formattedCurrency(currency: account.currency))
                        .font(.caption)
                        .foregroundStyle(pnlValue >= 0 ? .incomeGreen : .expenseRed)
                }
            }
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
        case .mutualFund: return "chart.pie.fill"
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
        case .mutualFund: return .accountMutualFund
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
        case .mutualFund:
            return account.fundHouse ?? "Mutual Fund"
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