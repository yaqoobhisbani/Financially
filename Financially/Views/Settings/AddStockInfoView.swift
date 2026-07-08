import SwiftUI
import SwiftData

struct AddStockInfoView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var companyName = ""
    @State private var ticker = ""
    @State private var currentRate = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Company") {
                    TextField("Company Name", text: $companyName)
                    TextField("Ticker (e.g. MEBL)", text: $ticker)
                        .textInputAutocapitalization(.characters)
                }

                Section("Current Rate") {
                    AmountField(amount: $currentRate)
                }

                FormErrorSection(message: errorMessage)
            }
            .navigationTitle("New Stock")
            .formToolbar(label: "Save", isDisabled: companyName.isEmpty || ticker.isEmpty) { save() }
        }
    }

    private func save() {
        guard !companyName.isEmpty else { errorMessage = "Company name is required"; return }
        guard !ticker.isEmpty else { errorMessage = "Ticker is required"; return }

        let rate = Decimal(string: currentRate) ?? 0
        let stock = StockInfo(companyName: companyName, ticker: ticker.uppercased(), currentRate: rate)
        modelContext.insert(stock)
        dismiss()
    }
}
