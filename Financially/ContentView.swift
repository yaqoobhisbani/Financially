import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("colorScheme") private var colorScheme: String = "System"

    var body: some View {
        #if os(macOS)
        NavigationSplitView {
            sidebarContent
        } detail: {
            DashboardView()
        }
        #else
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }

            AccountsListView()
                .tabItem {
                    Label("Accounts", systemImage: "creditcard.fill")
                }

            LoansListView()
                .tabItem {
                    Label("Loans", systemImage: "arrow.left.arrow.right")
                }

            SettingsView()
                .tabItem {
                    Label("More", systemImage: "ellipsis.circle.fill")
                }
        }
        #endif
    }

    @ViewBuilder
    private var sidebarContent: some View {
        List {
            NavigationLink(destination: DashboardView()) {
                Label("Dashboard", systemImage: "house.fill")
            }

            Section("Accounts") {
                NavigationLink(destination: filteredAccountsView(.bank)) {
                    Label("Bank", systemImage: "building.columns.fill")
                }
                NavigationLink(destination: filteredAccountsView(.cash)) {
                    Label("Cash", systemImage: "wallet.pass.fill")
                }
                NavigationLink(destination: filteredAccountsView(.psx)) {
                    Label("PSX", systemImage: "chart.line.uptrend.xyaxis")
                }
                NavigationLink(destination: filteredAccountsView(.mutualFund)) {
                    Label("Mutual Funds", systemImage: "chart.pie.fill")
                }
            }

            NavigationLink(destination: LoansListView()) {
                Label("Loans", systemImage: "arrow.left.arrow.right")
            }

            NavigationLink(destination: CreditorsListView()) {
                Label("Liabilities", systemImage: "arrow.right.circle")
            }

            Section("Tools") {
                NavigationLink(destination: ReportsListView()) {
                    Label("Reports", systemImage: "chart.bar.fill")
                }
                NavigationLink(destination: SettingsView()) {
                    Label("Settings", systemImage: "gearshape.fill")
                }
            }
        }
        .listStyle(.sidebar)
    }

    private func filteredAccountsView(_ type: AccountType) -> some View {
        AccountsListView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Account.self, Transaction.self, LedgerEntry.self, Debtor.self, Creditor.self, InvestmentEntry.self, Category.self], inMemory: true)
}