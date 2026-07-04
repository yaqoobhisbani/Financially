import SwiftUI
import SwiftData

struct PayBackView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let creditor: Creditor

    @State private var vm: LoanTransactionViewModel?
    @State private var sourceAccount: Account?
    @State private var amount = ""
    @State private var date = Date()
    @State private var description = ""
    @State private var isFullPayback = false
    @State private var showAccountPicker = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Source Account") {
                    AccountPickerButton(
                        label: "From",
                        accountName: sourceAccount?.name,
                        placeholder: "Select Bank or Cash account",
                        action: { showAccountPicker = true }
                    )
                }

                Section("Amount") {
                    Toggle("Full Payback", isOn: $isFullPayback)
                        .onChange(of: isFullPayback) { _, newValue in
                            if newValue { amount = "\(creditor.outstandingBalance)" }
                            else if amount == "\(creditor.outstandingBalance)" { amount = "" }
                        }
                    AmountField(amount: $amount)
                        .disabled(isFullPayback)
                    if let amountValue = Decimal(string: amount), amountValue > creditor.outstandingBalance {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.yellow)
                            Text("Amount exceeds outstanding balance").font(.caption).foregroundStyle(.red)
                        }
                    }
                }

                Section { DatePicker("Date", selection: $date, displayedComponents: .date) }
                Section("Notes") { TextField("Description (optional)", text: $description) }

                FormErrorSection(message: errorMessage)

                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("After this transaction:").font(.caption).foregroundStyle(.secondary)
                        HStack {
                            Text("Outstanding Liability")
                            Spacer()
                            Text(newOutstanding.formattedCurrency())
                        }
                    }
                }
            }
            .navigationTitle("Pay Back")
            .navigationBarTitleDisplayMode(.inline)
            .formToolbar(label: "Pay", isDisabled: sourceAccount == nil || amount.isEmpty) { save() }
            .sheet(isPresented: $showAccountPicker) {
                AccountPickerView(title: "Select Source", filterType: nil) { account in
                    sourceAccount = account
                }
            }
        }
    }

    private var newOutstanding: Decimal {
        guard let amountValue = Decimal(string: amount), amountValue > 0 else { return creditor.outstandingBalance }
        return max(0, creditor.outstandingBalance - amountValue)
    }

    private func save() {
        guard let source = sourceAccount else { errorMessage = "Please select a source account"; return }

        let vm = vm ?? LoanTransactionViewModel(modelContext: modelContext)
        self.vm = vm

        do {
            try vm.payBack(to: creditor, amount: amount, date: date, description: description.isEmpty ? nil : description, sourceAccountId: source.id)
            dismiss()
        } catch let error as LoanTransactionViewModel.LoanError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}