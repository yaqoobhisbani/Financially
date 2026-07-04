import SwiftUI
import SwiftData
import Charts

struct MonthlySummaryReport: View {
    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]
    @State private var selectedMonth = Date()

    private var monthTransactions: [Transaction] {
        allTransactions.filter { tx in
            Calendar.current.isDate(tx.date, equalTo: selectedMonth, toGranularity: .month)
        }
    }

    private var income: Decimal { monthTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount } }
    private var expense: Decimal { monthTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount } }
    private var netSavings: Decimal { income - expense }

    private var expenseByCategory: [(category: String, total: Decimal)] {
        let grouped = Dictionary(grouping: monthTransactions.filter { $0.type == .expense }) { $0.category ?? "Other" }
        return grouped.map { ($0.key, $0.value.reduce(0) { $0 + $1.amount }) }.sorted { $0.total > $1.total }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Button(action: { selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth }) {
                        Image(systemName: "chevron.left")
                    }
                    Text(selectedMonth.monthYear())
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                    Button(action: { selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth }) {
                        Image(systemName: "chevron.right")
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                List {
                    Section("Summary") {
                        HStack {
                            Text("Income")
                            Spacer()
                            Text(income.formattedCurrency()).foregroundStyle(.incomeGreen)
                        }
                        HStack {
                            Text("Expenses")
                            Spacer()
                            Text(expense.formattedCurrency()).foregroundStyle(.expenseRed)
                        }
                        HStack {
                            Text("Net")
                            Spacer()
                            Text(netSavings.formattedCurrency())
                                .foregroundStyle(netSavings >= 0 ? .incomeGreen : .expenseRed)
                        }
                    }

                    if !expenseByCategory.isEmpty {
                        Section("Expense Breakdown") {
                            Chart(expenseByCategory, id: \.category) { item in
                                SectorMark(angle: .value("Amount", item.total), innerRadius: .ratio(0.6))
                                    .foregroundStyle(by: .value("Category", item.category))
                            }
                            .frame(height: 180)
                        }
                    }

                    Section("Transactions (\(monthTransactions.count))") {
                        ForEach(monthTransactions) { tx in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(txTypeLabel(tx.type))
                                        .font(.headline)
                                    Text(tx.date.formattedDate())
                                        .font(.caption)
                                }
                                Spacer()
                                Text(tx.amount.formattedCurrency())
                                    .foregroundStyle(tx.type == .income ? .incomeGreen : .expenseRed)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Monthly Summary")
        }
    }

    private func txTypeLabel(_ type: TransactionType) -> String {
        switch type {
        case .income: return "Income"
        case .expense: return "Expense"
        case .transfer: return "Transfer"
        case .loanGiven: return "Loan Given"
        case .loanRepayment: return "Repayment"
        case .liabilityReceived: return "Received"
        case .liabilityPayback: return "Payback"
        case .investmentWithdrawal: return "Withdrawal"
        case .investmentAddCapital: return "Add Capital"
        case .investmentProfitLoss: return "P&L"
        }
    }
}