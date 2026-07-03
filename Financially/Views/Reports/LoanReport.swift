import SwiftUI
import SwiftData

struct LoanReport: View {
    @Query(sort: \Debtor.name) private var debtors: [Debtor]
    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]
    @State private var startDate = Date().startOfMonth
    @State private var endDate = Date()
    @State private var selectedPreset = DateRangePickerView.DatePreset.thisMonth
    @State private var filterStatus: FilterStatus = .all

    enum FilterStatus: String, CaseIterable {
        case all = "All"
        case active = "Active"
        case settled = "Settled"
    }

    private var filteredDebtors: [Debtor] {
        switch filterStatus {
        case .all: return debtors
        case .active: return debtors.filter { !$0.isSettled }
        case .settled: return debtors.filter { $0.isSettled }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DateRangePickerView(startDate: $startDate, endDate: $endDate, selectedPreset: $selectedPreset)

                Picker("Status", selection: $filterStatus) {
                    ForEach(FilterStatus.allCases, id: \.rawValue) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                List {
                    Section("Summary") {
                        HStack {
                            Text("Total Outstanding")
                            Spacer()
                            Text(debtors.reduce(0) { $0 + $1.outstandingBalance }.formattedCurrency())
                        }
                        HStack {
                            Text("Active Debtors")
                            Spacer()
                            Text("\(debtors.filter { !$0.isSettled }.count)")
                        }
                    }

                    ForEach(filteredDebtors) { debtor in
                        Section(debtor.name) {
                            LabeledContent("Outstanding", value: debtor.outstandingBalance.formattedCurrency())
                            LabeledContent("Total Lent", value: debtor.totalLent.formattedCurrency())
                            LabeledContent("Repaid", value: debtor.totalRepaid.formattedCurrency())
                            if debtor.isSettled {
                                Label("Settled", systemImage: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }

                    if debtors.isEmpty {
                        ContentUnavailableView("No Debtors", systemImage: "person.fill.questionmark", description: Text("No loans recorded yet"))
                    }
                }
            }
            .navigationTitle("Loan Report")
        }
    }
}