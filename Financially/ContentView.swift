import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var selection: AppTab = .dashboard
    @State private var showQuickActions = false
    @State private var quickActionsDetent: PresentationDetent = .medium
    @State private var activeQuickAction: QuickAction?

    var body: some View {
        TabView(selection: $selection) {
            Tab("Dashboard", systemImage: "house.fill", value: AppTab.dashboard) {
                DashboardView()
            }

            Tab("Accounts", systemImage: "creditcard.fill", value: AppTab.accounts) {
                AccountsListView()
            }

            Tab("Investments", systemImage: "chart.line.uptrend.xyaxis", value: AppTab.investments) {
                InvestmentsListView()
            }

            Tab("Committees", systemImage: "person.3.fill", value: AppTab.committees) {
                CommitteesListView()
            }

            Tab("More", systemImage: "ellipsis.circle", value: AppTab.more) {
                SettingsView()
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewBottomAccessory(isEnabled: selection == .dashboard) {
            QuickAddAccessory(onOpen: {
                quickActionsDetent = .medium
                showQuickActions = true
            })
        }
        .sheet(item: $activeQuickAction) { action in
            action.destination
        }
        .persistentGlassSheet(
            isPresented: $showQuickActions,
            detents: [.height(140), .medium, .large],
            selection: $quickActionsDetent,
            interactiveUpThrough: .height(140)
        ) {
            QuickActionsSheetContent(sections: quickActionSections)
        }
    }

    // MARK: - Quick Actions

    private func selectQuickAction(_ action: QuickAction) {
        showQuickActions = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            activeQuickAction = action
        }
    }

    private var quickActionSections: [QuickActionSection] {
        [
            QuickActionSection(title: "Most Used", items: [
                QuickActionItem(title: "Expense", systemImage: "arrow.up.circle.fill", tint: .loss) { selectQuickAction(.expense) },
                QuickActionItem(title: "Income", systemImage: "arrow.down.circle.fill", tint: .gain) { selectQuickAction(.income) },
                QuickActionItem(title: "Transfer", systemImage: "arrow.left.arrow.right", tint: themeManager.theme.accent) { selectQuickAction(.transfer) }
            ]),
            QuickActionSection(title: "Invest", items: [
                QuickActionItem(title: "Buy Stock", systemImage: "chart.bar.fill", tint: .indigo) { selectQuickAction(.buyStock) },
                QuickActionItem(title: "Invest MF", systemImage: "chart.pie.fill", tint: .teal) { selectQuickAction(.investMF) },
                QuickActionItem(title: "Buy Gold", systemImage: "diamond.fill", tint: .orange) { selectQuickAction(.buyGold) }
            ]),
            QuickActionSection(title: "People & Committees", items: [
                QuickActionItem(title: "Give Loan", systemImage: "arrow.right.circle.fill", tint: themeManager.theme.accent) { selectQuickAction(.giveLoan) },
                QuickActionItem(title: "Pay Committee", systemImage: "person.2.fill", tint: .teal) { selectQuickAction(.payCommittee) },
                QuickActionItem(title: "Pay Back", systemImage: "arrow.up.circle.fill", tint: .loss) { selectQuickAction(.payBack) }
            ])
        ]
    }
}

private enum AppTab: Hashable {
    case dashboard, accounts, investments, committees, more
}

// MARK: - Quick Action Routing

enum QuickAction: String, Identifiable {
    case expense, income, transfer, buyStock, investMF, buyGold, giveLoan, payCommittee, payBack

    var id: String { rawValue }

    @ViewBuilder
    var destination: some View {
        switch self {
        case .expense: AddExpenseView()
        case .income: AddIncomeView()
        case .transfer: TransferView()
        case .buyStock: InvestmentsListView(initialSegment: .psx)
        case .investMF: InvestmentsListView(initialSegment: .mutualFunds)
        case .buyGold: BuyCommodityView()
        case .giveLoan: LoansListView(initialSegment: .debtors)
        case .payCommittee: CommitteesListView()
        case .payBack: LoansListView(initialSegment: .creditors)
        }
    }
}

#Preview {
    ContentView()
        .environment(ThemeManager.shared)
        .modelContainer(for: [Account.self, Transaction.self, LedgerEntry.self, Debtor.self, Creditor.self, InvestmentEntry.self, Category.self], inMemory: true)
}
