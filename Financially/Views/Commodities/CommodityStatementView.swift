import SwiftUI
import SwiftData

struct CommodityStatementView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var startDate: Date = Date().startOfMonth
    @State private var endDate: Date = Date()
    @State private var selectedPreset: DatePreset = .thisMonth
    @State private var selectedTransaction: Transaction?

    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]

    enum DatePreset: String, CaseIterable {
        case thisMonth = "This Month"
        case thisQuarter = "This Quarter"
        case thisYear = "This Year"
        case all = "All"
        case custom = "Custom"
    }

    private var filteredTransactions: [Transaction] {
        allTransactions
            .filter { $0.type == .commodityBuy || $0.type == .commoditySell }
            .filter { $0.date >= startDate && $0.date <= endDate.endOfDay }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                dateFilterBar

                List {
                    ForEach(filteredTransactions) { tx in
                        TransactionRowView(transaction: tx, showIcon: true)
                            .contentShape(Rectangle())
                            .onTapGesture { selectedTransaction = tx }
                    }

                    if filteredTransactions.isEmpty {
                        ContentUnavailableView("No Entries", systemImage: "tray", description: Text("No commodity transactions in this period"))
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .groupedScreenBackground()
            .navigationTitle("Commodity Statement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .tint(.primary)
                }
            }
            .sheet(item: $selectedTransaction) { tx in
                NavigationStack {
                    TransactionDetailView(transaction: tx)
                }
            }
        }
    }

    private var dateFilterBar: some View {
        VStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(DatePreset.allCases, id: \.rawValue) { preset in
                        Button(preset.rawValue) {
                            applyPreset(preset)
                        }
                        .buttonStyle(.bordered)
                        .tint(selectedPreset == preset ? .accentColor : .gray)
                    }
                }
                .padding(.horizontal)
            }

            if selectedPreset == .custom {
                HStack {
                    DatePicker("From", selection: $startDate, displayedComponents: .date)
                    DatePicker("To", selection: $endDate, displayedComponents: .date)
                }
                .datePickerStyle(.compact)
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
    }

    private func applyPreset(_ preset: DatePreset) {
        selectedPreset = preset
        switch preset {
        case .thisMonth:
            startDate = Date().startOfMonth
            endDate = Date()
        case .thisQuarter:
            startDate = Calendar.current.date(from: Calendar.current.dateComponents([.year], from: Date())) ?? Date()
            endDate = Date()
        case .thisYear:
            startDate = Date().startOfYear
            endDate = Date()
        case .all:
            startDate = Date.distantPast
            endDate = Date.distantFuture
        case .custom:
            break
        }
    }
}
