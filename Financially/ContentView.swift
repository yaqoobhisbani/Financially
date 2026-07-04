import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
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

            InvestmentsListView()
                .tabItem {
                    Label("Investments", systemImage: "chart.line.uptrend.xyaxis")
                }

            CommitteesListView()
                .tabItem {
                    Label("Committees", systemImage: "person.3.fill")
                }

            SettingsView()
                .tabItem {
                    Label("More", systemImage: "ellipsis.circle.fill")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Account.self, Transaction.self, LedgerEntry.self, Debtor.self, Creditor.self, InvestmentEntry.self, Category.self], inMemory: true)
}
