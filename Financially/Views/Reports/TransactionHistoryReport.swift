import SwiftUI
import SwiftData

struct TransactionHistoryReport: View {
    @Environment(\.modelContext) private var modelContext

    @State private var vm: TransactionHistoryReportViewModel?
    @State private var searchText = ""
    @State private var startDate = Date().startOfMonth
    @State private var endDate = Date()
    @State private var selectedPreset = DateRangePickerView.DatePreset.thisMonth
    @State private var selectedType: TransactionType?

    private var filteredTransactions: [Transaction] {
        guard let vm else { return [] }
        return vm.filteredTransactions(searchText: searchText, startDate: startDate, endDate: endDate, selectedType: selectedType)
    }

    var body: some View {
        VStack(spacing: 0) {
            DateRangePickerView(startDate: $startDate, endDate: $endDate, selectedPreset: $selectedPreset)
                .padding(.horizontal)
                .padding(.top, 8)

            SearchBarView(text: $searchText, placeholder: "Search transactions")
                .padding(.horizontal)
                .padding(.top, 8)

            typeFilterPicker

            List {
                ForEach(filteredTransactions) { tx in
                    TransactionRowView(transaction: tx, showIcon: false)
                }
            }
        }
        .navigationTitle("Transaction History")
        .onAppear {
            vm = TransactionHistoryReportViewModel(modelContext: modelContext)
        }
    }

    private var typeFilterPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                Button("All") { selectedType = nil }
                    .buttonStyle(.bordered)
                    .tint(selectedType == nil ? .accentColor : .gray)
                ForEach(TransactionType.allCases, id: \.rawValue) { type in
                    Button(type.displayLabel) {
                        selectedType = selectedType == type ? nil : type
                    }
                    .buttonStyle(.bordered)
                    .tint(selectedType == type ? .accentColor : .gray)
                }
            }
            .padding(.horizontal)
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
}