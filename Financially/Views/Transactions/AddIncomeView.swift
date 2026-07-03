import SwiftUI
import SwiftData

struct AddIncomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let preselectedAccount: Account?

    @State private var destinationAccount: Account?
    @State private var amount = ""
    @State private var category: Category?
    @State private var date = Date()
    @State private var description = ""
    @State private var showAccountPicker = false
    @State private var showCategoryPicker = false
    @State private var errorMessage: String?

    @Query(sort: \Category.sortOrder)
    private var allCategories: [Category]

    private var incomeCategories: [Category] {
        allCategories.filter { $0.categoryType == .income }
    }

    init(preselectedAccount: Account? = nil) {
        self.preselectedAccount = preselectedAccount
        _destinationAccount = State(initialValue: preselectedAccount)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    Button(action: { showAccountPicker = true }) {
                        HStack {
                            Text("Destination")
                            Spacer()
                            if let account = destinationAccount {
                                Text(account.name)
                                    .foregroundStyle(.primary)
                            } else {
                                Text("Select account")
                                    .foregroundStyle(.secondary)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Amount") {
                    HStack {
                        Text("PKR")
                        TextField("0", text: $amount)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                            .multilineTextAlignment(.trailing)
                    }
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

                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Add Income")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveIncome() }
                        .disabled(destinationAccount == nil || amount.isEmpty || category == nil)
                }
            }
            .sheet(isPresented: $showAccountPicker) {
                AccountPickerView(title: "Select Destination", filterType: nil) { account in
                    destinationAccount = account
                }
            }
            .sheet(isPresented: $showCategoryPicker) {
                categoryPickerSheet
            }
        }
    }

    private var categoryPickerSheet: some View {
        NavigationStack {
            List(incomeCategories) { cat in
                Button {
                    category = cat
                    showCategoryPicker = false
                } label: {
                    Label(cat.name, systemImage: cat.icon)
                }
            }
            .navigationTitle("Category")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showCategoryPicker = false }
                }
            }
        }
    }

    private func saveIncome() {
        guard let account = destinationAccount, let amountValue = Decimal(string: amount), amountValue > 0 else {
            errorMessage = "Please enter a valid amount"
            return
        }

        let service = LedgerService(modelContext: modelContext)
        let request = TransactionRequest(
            type: .income,
            amount: amountValue,
            date: date,
            category: category?.name,
            description: description.isEmpty ? nil : description,
            sourceAccountId: account.id
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