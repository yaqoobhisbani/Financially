import SwiftUI
import SwiftData

struct AccountStatementView: View {
    @Environment(\.dismiss) private var dismiss
    let account: Account

    @State private var startDate: Date = Date().startOfMonth
    @State private var endDate: Date = Date()
    @State private var selectedPreset: DatePreset = .thisMonth

    @Query private var allEntries: [LedgerEntry]

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
        allEntries.filter { $0.date >= startDate && $0.date <= endDate }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                dateFilterBar

                List {
                    Section {
                        HStack {
                            Text("Opening Balance")
                            Spacer()
                            Text(openingBalance.formattedCurrency(currency: account.currency))
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Text("Closing Balance")
                            Spacer()
                            Text(closingBalance.formattedCurrency(currency: account.currency))
                                .bold()
                        }
                    }

                    ForEach(filteredEntries) { entry in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(entry.entryType == .debit ? "Debit" : "Credit")
                                    .font(.headline)
                                Text(entry.date.formattedDate())
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(entry.amount.formattedCurrency(currency: account.currency))
                                Text("Bal: \(entry.runningBalance.formattedCurrency(currency: account.currency))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    if filteredEntries.isEmpty {
                        Text("No entries in this period")
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    }
                }
                #if os(iOS)
                .listStyle(.insetGrouped)
                #endif
            }
            .navigationTitle("Statement")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
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

    private var openingBalance: Decimal {
        filteredEntries.last?.runningBalance ?? account.currentBalance
    }

    private var closingBalance: Decimal {
        filteredEntries.first?.runningBalance ?? account.currentBalance
    }
}