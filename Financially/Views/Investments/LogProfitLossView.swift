import SwiftUI
import SwiftData

struct LogProfitLossView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let account: Account

    @State private var entryType: InvestmentEntryType = .profit
    @State private var amount = ""
    @State private var date = Date()
    @State private var period = ""
    @State private var description = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $entryType) {
                        Text("Profit").tag(InvestmentEntryType.profit)
                        Text("Loss").tag(InvestmentEntryType.loss)
                    }
                }

                Section("Amount") {
                    HStack {
                        Text("PKR")
                        TextField("0", text: $amount)
                        #if os(iOS)
                            .keyboardType(.decimalPad)
                        #endif
                    }
                }

                Section {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Period (e.g. June 2026)", text: $period)
                }

                Section("Notes") {
                    TextField("Description", text: $description)
                }
            }
            .navigationTitle("Log \(entryType == .profit ? "Profit" : "Loss")")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(amount.isEmpty)
                }
            }
        }
    }

    private func save() {
        guard let amountValue = Decimal(string: amount), amountValue > 0 else { return }

        let entry = InvestmentEntry(
            investmentAccountId: account.id,
            type: entryType,
            amount: amountValue,
            date: date,
            period: period.isEmpty ? nil : period,
            description: description.isEmpty ? nil : description
        )

        if entryType == .profit {
            account.totalProfitLoss += amountValue
        } else {
            account.totalProfitLoss -= amountValue
        }
        account.updatedAt = Date()

        modelContext.insert(entry)
        dismiss()
    }
}