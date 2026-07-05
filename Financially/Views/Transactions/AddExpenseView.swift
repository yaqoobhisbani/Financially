import SwiftUI
import SwiftData

struct AddExpenseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let preselectedAccount: Account?

    @Query private var accounts: [Account]
    @State private var sourceAccount: Account?
    @State private var isOutside = false
    @State private var amount = ""
    @State private var category: Category?
    @State private var date = Date()
    @State private var description = ""
    @State private var showAccountPicker = false
    @State private var showCategoryPicker = false
    @State private var errorMessage: String?

    @Query(sort: \Category.sortOrder)
    private var allCategories: [Category]

    private var expenseCategories: [Category] {
        allCategories.filter { $0.categoryType == .expense }
    }

    init(preselectedAccount: Account? = nil) {
        self.preselectedAccount = preselectedAccount
        _sourceAccount = State(initialValue: preselectedAccount)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    AccountPickerButton(
                        label: "From",
                        accountName: sourceAccount?.name,
                        placeholder: isOutside ? "Outside — No Account" : "Select account",
                        isOutside: isOutside,
                        action: { showAccountPicker = true }
                    )
                }

                Section("Amount") {
                    AmountField(amount: $amount)
                }

                Section("Category") {
                    Button(action: { showCategoryPicker = true }) {
                        HStack {
                            if let category = category {
                                Label(category.name, systemImage: category.icon)
                                    .foregroundStyle(.primary)
                            } else {
                                Text("Select category")
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section("Notes") {
                    TextField("Description (optional)", text: $description)
                }

                FormErrorSection(message: errorMessage)
            }
            .navigationTitle("Add Expense")
            .formToolbar(label: "Save", isDisabled: (sourceAccount == nil && !isOutside) || amount.isEmpty || category == nil) { saveExpense() }
            .sheet(isPresented: $showAccountPicker) {
                AccountPickerView(accounts: accounts, title: "Select Account", filterType: nil, showNoneOption: true) { account in
                    if let account {
                        sourceAccount = account
                        isOutside = false
                    } else {
                        sourceAccount = nil
                        isOutside = true
                    }
                }
            }
            .sheet(isPresented: $showCategoryPicker) {
                categoryPickerSheet
            }
        }
    }

    private var categoryPickerSheet: some View {
        NavigationStack {
            List(expenseCategories) { cat in
                Label(cat.name, systemImage: cat.icon)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        category = cat
                        showCategoryPicker = false
                    }
            }
            .navigationTitle("Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showCategoryPicker = false }
                }
            }
        }
    }

    private func saveExpense() {
        guard let amountValue = Decimal(string: amount), amountValue > 0 else {
            errorMessage = "Please enter a valid amount"
            return
        }

        let service = LedgerService(modelContext: modelContext)
        let request = TransactionRequest(
            type: .expense,
            amount: amountValue,
            date: date,
            category: category?.name,
            description: description.isEmpty ? nil : description,
            sourceAccountId: isOutside ? nil : sourceAccount?.id
        )

        do {
            try service.execute(request)
            dismiss()
        } catch let error as ValidationError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}