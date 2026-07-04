import SwiftUI
import SwiftData

struct DebtorDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var debtor: Debtor

    @Query private var transactions: [Transaction]
    @State private var showGiveLoan = false
    @State private var showRepayment = false
    @State private var selectedTransaction: Transaction?

    init(debtor: Debtor) {
        self.debtor = debtor
        let entityId = debtor.id
        _transactions = Query(filter: #Predicate<Transaction> { $0.relatedEntityId == entityId }, sort: \.date, order: .reverse)
    }

    var body: some View {
        List {
            contactSection
            summarySection
            actionsSection
            historySection
        }
        .navigationTitle(debtor.name)
        .sheet(isPresented: $showGiveLoan) {
            GiveLoanView(debtor: debtor)
        }
        .sheet(isPresented: $showRepayment) {
            RecordRepaymentView(debtor: debtor)
        }
    }

    private var contactSection: some View {
        Section("Contact") {
            if let phone = debtor.phone {
                Label(phone, systemImage: "phone")
            }
            if let email = debtor.email {
                Label(email, systemImage: "envelope")
            }
            if debtor.phone == nil && debtor.email == nil {
                Text("No contact info")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var summarySection: some View {
        Section("Summary") {
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Outstanding")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(debtor.outstandingBalance.formattedCurrency())
                            .font(.title.bold())
                            .foregroundStyle(debtor.outstandingBalance > 0 ? .red : .secondary)
                    }
                    Spacer()
                    if debtor.isSettled {
                        Label("Settled", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }

                Divider()

                HStack {
                    VStack(alignment: .leading) {
                        Text("Total Lent")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(debtor.totalLent.formattedCurrency())
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Repaid")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(debtor.totalRepaid.formattedCurrency())
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var actionsSection: some View {
        Section("Actions") {
            Button(action: { showGiveLoan = true }) {
                Label("Give Loan", systemImage: "arrow.right.circle")
            }
            Button(action: { showRepayment = true }) {
                Label("Record Repayment", systemImage: "arrow.left.circle")
            }
            .disabled(debtor.isSettled)
        }
    }

    private var historySection: some View {
        Section("History") {
            ForEach(transactions) { tx in
                HStack {
                    VStack(alignment: .leading) {
                        Text(tx.type == .loanGiven ? "Loan Given" : "Repayment Received")
                            .font(.headline)
                        Text(tx.date.formattedDate())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let desc = tx.desc {
                            Text(desc)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(tx.amount.formattedCurrency())
                            .foregroundStyle(tx.type == .loanGiven ? .expenseRed : .incomeGreen)
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
                .onTapGesture { selectedTransaction = tx }
            }

            if transactions.isEmpty {
                EmptyStateView(title: "No transactions yet", systemImage: "arrow.left.arrow.right")
            }
        }
        .sheet(item: $selectedTransaction) { tx in
            NavigationStack {
                TransactionDetailView(transaction: tx)
            }
        }
    }
}