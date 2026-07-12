import SwiftUI
import SwiftData

struct IncomeReport: View {
    @Environment(\.modelContext) private var modelContext

    @State private var vm: ExpenseIncomeReportViewModel?
    @State private var startDate = Date().startOfMonth
    @State private var endDate = Date()
    @State private var selectedPreset = DateRangePickerView.DatePreset.thisMonth

    private var incomes: [Transaction] {
        guard let vm else { return [] }
        return vm.filtered(type: .income, startDate: startDate, endDate: endDate)
    }

    private var totalIncome: Decimal { vm?.total(incomes) ?? 0 }
    private var byCategory: [(category: String, total: Decimal)] { vm?.byCategory(incomes) ?? [] }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DateRangePickerView(startDate: $startDate, endDate: $endDate, selectedPreset: $selectedPreset)
                    .padding(.horizontal)
                    .padding(.top, 8)

                List {
                    Section {
                        HStack {
                            Text("Total Income")
                            Spacer()
                            Text(totalIncome.formattedCurrency())
                                .font(.title3.bold())
                                .foregroundStyle(.incomeGreen)
                        }
                    }

                    Section("By Source") {
                        ForEach(byCategory, id: \.category) { item in
                            HStack {
                                Text(item.category)
                                Spacer()
                                Text(item.total.formattedCurrency())
                            }
                        }
                    }

                    if byCategory.isEmpty {
                        ContentUnavailableView("No Income", systemImage: "arrow.down.circle", description: Text("No income found in this period"))
                    }

                    Section("All Transactions") {
                        ForEach(incomes) { tx in
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
                                    .foregroundStyle(.incomeGreen)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .groupedScreenBackground()
            .navigationTitle("Income Report")
        }
        .onAppear {
            vm = ExpenseIncomeReportViewModel(modelContext: modelContext)
        }
    }
}