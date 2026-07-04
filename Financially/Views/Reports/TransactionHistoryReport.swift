import SwiftUI
import SwiftData

struct TransactionHistoryReport: View {
    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]
    @Query private var allAccounts: [Account]
    @Query(sort: \Debtor.name) private var allDebtors: [Debtor]
    @Query(sort: \Creditor.name) private var allCreditors: [Creditor]

    @State private var searchText = ""
    @State private var startDate = Date().startOfMonth
    @State private var endDate = Date()
    @State private var selectedPreset = DateRangePickerView.DatePreset.thisMonth
    @State private var selectedType: TransactionType?

    var filteredTransactions: [Transaction] {
        var result = allTransactions
        result = result.filter { $0.date >= startDate && $0.date <= endDate.endOfDay }
        if let type = selectedType {
            result = result.filter { $0.type == type }
        }
        if !searchText.isEmpty {
            result = result.filter {
                ($0.desc ?? "").localizedCaseInsensitiveContains(searchText) ||
                ($0.category ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
        return result
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
                    HStack {
                        VStack(alignment: .leading) {
                            Text(txTypeLabel(tx.type))
                                .font(.headline)
                            Text(tx.date.formattedDate())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let desc = tx.desc, !desc.isEmpty {
                                Text(desc)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text(tx.amount.formattedCurrency())
                            if let category = tx.category {
                                Text(category)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Transaction History")
    }

    private var typeFilterPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                Button("All") { selectedType = nil }
                    .buttonStyle(.bordered)
                    .tint(selectedType == nil ? .accentColor : .gray)
                ForEach(TransactionType.allCases, id: \.rawValue) { type in
                    Button(txTypeLabel(type)) {
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

    private func txTypeLabel(_ type: TransactionType) -> String {
        switch type {
        case .income: return "Income"
        case .expense: return "Expense"
        case .transfer: return "Transfer"
        case .investmentWithdrawal: return "Withdrawal"
        case .investmentAddCapital: return "Add Capital"
        case .loanGiven: return "Loan Given"
        case .loanRepayment: return "Repayment"
        case .liabilityReceived: return "Received"
        case .liabilityPayback: return "Payback"
        case .investmentProfitLoss: return "P&L"
        }
    }
}

extension TransactionType: @retroactive CaseIterable {
    public static var allCases: [TransactionType] {
        [.income, .expense, .transfer, .loanGiven, .loanRepayment, .liabilityReceived, .liabilityPayback, .investmentWithdrawal, .investmentAddCapital, .investmentProfitLoss]
    }
}