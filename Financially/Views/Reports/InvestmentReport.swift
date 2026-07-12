import SwiftUI
import SwiftData

struct InvestmentReport: View {
    @Environment(\.modelContext) private var modelContext

    @State private var vm: InvestmentReportViewModel?
    @State private var startDate = Date().startOfMonth
    @State private var endDate = Date()
    @State private var selectedPreset = DateRangePickerView.DatePreset.thisMonth

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DateRangePickerView(startDate: $startDate, endDate: $endDate, selectedPreset: $selectedPreset)
                    .padding(.horizontal)
                    .padding(.top, 8)

                List {
                    if let vm {
                        Section {
                            HStack {
                                Text("Total Investment Value")
                                Spacer()
                                Text(vm.investmentAccounts.reduce(0) { $0 + $1.currentValue }.formattedCurrency())
                                    .font(.headline)
                            }
                            HStack {
                                Text("Total Invested")
                                Spacer()
                                Text(vm.investmentAccounts.reduce(0) { $0 + $1.investedAmount }.formattedCurrency())
                            }
                            HStack {
                                Text("Total P&L")
                                Spacer()
                                let totalPL = vm.investmentAccounts.reduce(0) { $0 + $1.totalProfitLoss }
                                Text(totalPL.formattedCurrency())
                                    .foregroundStyle(totalPL >= 0 ? .incomeGreen : .expenseRed)
                            }
                        }

                        ForEach(vm.investmentAccounts) { account in
                            Section(account.name) {
                                let entries = vm.entries(for: account, startDate: startDate, endDate: endDate)
                                if entries.isEmpty {
                                    Text("No entries in this period")
                                        .foregroundStyle(.secondary)
                                }
                                ForEach(entries) { entry in
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(entry.type == .profit ? "Profit" : "Loss")
                                                .font(.headline)
                                            Text(entry.date.formattedDate())
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Text(entry.amount.formattedCurrency())
                                            .foregroundStyle(entry.type == .profit ? .incomeGreen : .expenseRed)
                                    }
                                }
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .groupedScreenBackground()
            .navigationTitle("Investment Report")
        }
        .onAppear {
            vm = InvestmentReportViewModel(modelContext: modelContext)
        }
    }
}