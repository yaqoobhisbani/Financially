import SwiftUI
import SwiftData

struct LiabilityReport: View {
    @Query(sort: \Creditor.name) private var creditors: [Creditor]
    @State private var startDate = Date().startOfMonth
    @State private var endDate = Date()
    @State private var selectedPreset = DateRangePickerView.DatePreset.thisMonth
    @State private var filterStatus: FilterStatus = .all

    enum FilterStatus: String, CaseIterable {
        case all = "All"
        case active = "Active"
        case settled = "Settled"
    }

    var filteredCreditors: [Creditor] {
        switch filterStatus {
        case .all: return creditors
        case .active: return creditors.filter { !$0.isSettled }
        case .settled: return creditors.filter { $0.isSettled }
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
                            Text(creditors.reduce(0) { $0 + $1.outstandingBalance }.formattedCurrency())
                        }
                        HStack {
                            Text("Active Liabilities")
                            Spacer()
                            Text("\(creditors.filter { !$0.isSettled }.count)")
                        }
                    }

                    ForEach(filteredCreditors) { creditor in
                        Section(creditor.name) {
                            LabeledContent("Outstanding", value: creditor.outstandingBalance.formattedCurrency())
                            LabeledContent("Total Received", value: creditor.totalReceived.formattedCurrency())
                            LabeledContent("Returned", value: creditor.totalReturned.formattedCurrency())
                            if creditor.isSettled {
                                Label("Settled", systemImage: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }

                    if creditors.isEmpty {
                        ContentUnavailableView("No Creditors", systemImage: "person.fill.questionmark", description: Text("No liabilities recorded yet"))
                    }
                }
            }
            .navigationTitle("Liability Report")
        }
    }
}