import SwiftUI
import SwiftData

struct AccountStatementView: View {
    @Environment(\.dismiss) private var dismiss
    let account: Account

    @State private var startDate: Date = Date().startOfMonth
    @State private var endDate: Date = Date()
    @State private var selectedPreset: DatePreset = .thisMonth
    @State private var selectedTransaction: Transaction?

    @Query private var allEntries: [LedgerEntry]
    @Query private var allTransactions: [Transaction]

    enum DatePreset: String, CaseIterable {
        case thisMonth = "This Month"
        case thisQuarter = "This Quarter"
        case thisYear = "This Year"
        case all = "All"
        case custom = "Custom"
    }

    init(account: Account) {
        self.account = account
        let accountId = account.id
        _allEntries = Query(filter: #Predicate<LedgerEntry> { $0.accountId == accountId }, sort: \.date, order: .reverse)
    }

    var filteredEntries: [LedgerEntry] {
        allEntries.filter { $0.date >= startDate && $0.date <= endDate.endOfDay }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                dateFilterBar

                List {
                    openingClosingSection

                    ForEach(filteredEntries) { entry in
                        LedgerRowView(entry: entry, currency: account.currency)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedTransaction = allTransactions.first { $0.id == entry.transactionId }
                            }
                    }

                    if filteredEntries.isEmpty {
                        ContentUnavailableView("No Entries", systemImage: "tray", description: Text("No transactions in this period"))
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Statement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $selectedTransaction) { tx in
                NavigationStack {
                    TransactionDetailView(transaction: tx)
                }
            }
        }
    }

    private var openingClosingSection: some View {
        Section {
            HStack {
                Label("Opening Balance", systemImage: "arrow.forward")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(openingBalance.formattedCurrency(currency: account.currency))
            }
            HStack {
                Label("Closing Balance", systemImage: "arrow.down.left.circle")
                    .fontWeight(.semibold)
                Spacer()
                Text(closingBalance.formattedCurrency(currency: account.currency))
                    .fontWeight(.bold)
            }
            HStack {
                Label("Net Change", systemImage: "arrow.up.arrow.down")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(netChange.formattedCurrency(currency: account.currency))
                    .foregroundStyle(netChange >= 0 ? .incomeGreen : .expenseRed)
                    .fontWeight(.semibold)
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
            let components = Calendar.current.dateComponents([.year], from: Date())
            startDate = Calendar.current.date(from: components) ?? Date()
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

    private var netChange: Decimal {
        closingBalance - openingBalance
    }

    private var openingBalance: Decimal {
        filteredEntries.last?.runningBalance ?? account.currentBalance
    }

    private var closingBalance: Decimal {
        filteredEntries.first?.runningBalance ?? account.currentBalance
    }
}