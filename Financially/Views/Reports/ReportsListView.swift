import SwiftUI

struct ReportsListView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("General") {
                    NavigationLink(destination: TransactionHistoryReport()) {
                        Label("Transaction History", systemImage: "list.bullet.rectangle")
                    }
                    NavigationLink(destination: MonthlySummaryReport()) {
                        Label("Monthly Summary", systemImage: "calendar")
                    }
                    NavigationLink(destination: NetWorthChart()) {
                        Label("Net Worth Over Time", systemImage: "chart.line.uptrend.xyaxis")
                    }
                }

                Section("Income & Expenses") {
                    NavigationLink(destination: ExpenseReport()) {
                        Label("Expense Report", systemImage: "arrow.up.circle")
                    }
                    NavigationLink(destination: IncomeReport()) {
                        Label("Income Report", systemImage: "arrow.down.circle")
                    }
                }

                Section("Investments") {
                    NavigationLink(destination: InvestmentReport()) {
                        Label("Investment Report", systemImage: "chart.pie")
                    }
                }

                Section("Loans & Liabilities") {
                    NavigationLink(destination: LoanReport()) {
                        Label("Loan Report", systemImage: "arrow.left.arrow.right")
                    }
                    NavigationLink(destination: LiabilityReport()) {
                        Label("Liability Report", systemImage: "arrow.right.circle")
                    }
                }
            }
            .navigationTitle("Reports")
        }
    }
}