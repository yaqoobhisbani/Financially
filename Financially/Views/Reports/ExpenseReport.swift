import SwiftUI
import SwiftData

struct ExpenseReport: View {
    @Environment(\.modelContext) private var modelContext

    @State private var vm: ExpenseIncomeReportViewModel?
    @State private var startDate = Date().startOfMonth
    @State private var endDate = Date()
    @State private var selectedPreset = DateRangePickerView.DatePreset.thisMonth

    private var expenses: [Transaction] {
        guard let vm else { return [] }
        return vm.filtered(type: .expense, startDate: startDate, endDate: endDate)
    }

    private var totalExpense: Decimal { vm?.total(expenses) ?? 0 }
    private var byCategory: [(category: String, total: Decimal)] { vm?.byCategory(expenses) ?? [] }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DateRangePickerView(startDate: $startDate, endDate: $endDate, selectedPreset: $selectedPreset)
                    .padding(.horizontal)
                    .padding(.top, 8)

                List {
                    Section {
                        HStack {
                            Text("Total Expenses")
                            Spacer()
                            Text(totalExpense.formattedCurrency())
                                .bold()
                        }
                    }

                    Section("By Category") {
                        ForEach(byCategory, id: \.category) { item in
                            HStack {
                                Text(item.category)
                                Spacer()
                                Text(item.total.formattedCurrency())
                            }
                        }
                    }

                    if byCategory.isEmpty {
                        ContentUnavailableView("No Expenses", systemImage: "arrow.up.circle", description: Text("No expenses found in this period"))
                    }

                    Section("All Transactions") {
                        ForEach(expenses) { tx in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(tx.category ?? "Other")
                                        .font(.headline)
                                    Text(tx.date.formattedDate())
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(tx.amount.formattedCurrency())
                                    .foregroundStyle(.expenseRed)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Expense Report")
        }
        .onAppear {
            vm = ExpenseIncomeReportViewModel(modelContext: modelContext)
        }
    }
}