import SwiftUI
import SwiftData

struct CreditorDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var creditor: Creditor

    @Query private var transactions: [Transaction]
    @State private var showReceive = false
    @State private var showPayback = false

    init(creditor: Creditor) {
        self.creditor = creditor
        let entityId = creditor.id
        _transactions = Query(filter: #Predicate<Transaction> { $0.relatedEntityId == entityId }, sort: \.date, order: .reverse)
    }

    var body: some View {
        List {
            contactSection
            summarySection
            actionsSection
            historySection
        }
        .navigationTitle(creditor.name)
        .sheet(isPresented: $showReceive) {
            ReceiveMoneyView(creditor: creditor)
        }
        .sheet(isPresented: $showPayback) {
            PayBackView(creditor: creditor)
        }
    }

    private var contactSection: some View {
        Section("Contact") {
            if let phone = creditor.phone {
                HStack(alignment: .firstTextBaseline) {
                    Image(systemName: "phone")
                        .foregroundStyle(.secondary)
                    Text(phone)
                }
            }
            if let email = creditor.email {
                HStack(alignment: .firstTextBaseline) {
                    Image(systemName: "envelope")
                        .foregroundStyle(.secondary)
                    Text(email)
                }
            }
            if creditor.phone == nil && creditor.email == nil {
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
                        Text(creditor.outstandingBalance.formattedCurrency())
                            .font(.title.bold())
                            .foregroundStyle(creditor.outstandingBalance > 0 ? .orange : .secondary)
                    }
                    Spacer()
                    if creditor.isSettled {
                        Label("Settled", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }

                Divider()

                HStack {
                    VStack(alignment: .leading) {
                        Text("Total Received")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(creditor.totalReceived.formattedCurrency())
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("Returned")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(creditor.totalReturned.formattedCurrency())
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var actionsSection: some View {
        Section("Actions") {
            Button(action: { showReceive = true }) {
                Label("Receive Money", systemImage: "arrow.down.circle")
            }
            Button(action: { showPayback = true }) {
                Label("Pay Back", systemImage: "arrow.up.circle")
            }
            .disabled(creditor.isSettled)
        }
    }

    private var historySection: some View {
        Section("History") {
            ForEach(transactions) { tx in
                HStack {
                    VStack(alignment: .leading) {
                        Text(tx.type == .liabilityReceived ? "Received" : "Payback")
                            .font(.headline)
                        Text(tx.date.formattedDate())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let description = tx.desc {
                            Text(description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(tx.amount.formattedCurrency())
                            .foregroundStyle(tx.type == .liabilityReceived ? .incomeGreen : .expenseRed)
                    }
                }
            }

            if transactions.isEmpty {
                Text("No transactions yet")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
    }
}