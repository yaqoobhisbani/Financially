import SwiftUI
import SwiftData
import Charts

struct MonthlySummaryReport: View {
    @Environment(\.modelContext) private var modelContext

    @State private var vm: MonthlySummaryReportViewModel?
    @State private var selectedMonth = Date()

    private var monthTransactions: [Transaction] {
        guard let vm else { return [] }
        return vm.transactions(for: selectedMonth)
    }

    private var income: Decimal { vm?.income(monthTransactions) ?? 0 }
    private var expense: Decimal { vm?.expense(monthTransactions) ?? 0 }
    private var netSavings: Decimal { income - expense }
    private var expenseByCategory: [(category: String, total: Decimal)] {
        vm?.expenseByCategory(monthTransactions) ?? []
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
                            TransactionRowView(transaction: tx, showIcon: false)
                        }
                    }
                }
            }
            .navigationTitle("Monthly Summary")
        }
        .onAppear {
            vm = MonthlySummaryReportViewModel(modelContext: modelContext)
        }
    }
}