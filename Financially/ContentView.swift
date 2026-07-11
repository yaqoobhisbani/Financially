import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Dashboard", systemImage: "house.fill") {
                DashboardView()
            }

            Tab("Accounts", systemImage: "creditcard.fill") {
                AccountsListView()
            }

            Tab("Investments", systemImage: "chart.line.uptrend.xyaxis") {
                InvestmentsListView()
            }

            Tab("Committees", systemImage: "person.3.fill") {
                CommitteesListView()
            }

            Tab(role: .search) {
                GlobalSearchView()
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Account.self, Transaction.self, LedgerEntry.self, Debtor.self, Creditor.self, InvestmentEntry.self, Category.self], inMemory: true)
}
