import SwiftUI
import SwiftData

struct AddMFSchemeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var schemeName = ""
    @State private var fundCode = ""
    @State private var fundHouse = ""
    @State private var showCustomFundHouse = false
    @State private var customFundHouse = ""
    @State private var navPrice = ""
    @State private var errorMessage: String?

    private var selectedFundHouse: String {
        fundHouse == "Other" ? customFundHouse : fundHouse
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Scheme Details") {
                    TextField("Scheme Name", text: $schemeName)
                    TextField("Fund Code", text: $fundCode)
                    if showCustomFundHouse {
                        TextField("Fund House", text: $customFundHouse)
                    } else {
                        Picker("Fund House", selection: $fundHouse) {
                            Text("Optional").tag("")
                            ForEach(FundHouses.all, id: \.self) { house in
                                Text(house).tag(house)
                            }
                            Text("Other").tag("Other")
                        }
                    }
                }

                Section("NAV") {
                    HStack {
                        Text("NAV Price")
                        Spacer()
                        TextField("0", text: $navPrice)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                FormErrorSection(message: errorMessage)
            }
            .navigationTitle("Add Scheme")
            .navigationBarTitleDisplayMode(.inline)
            .formToolbar(label: "Save", isDisabled: schemeName.isEmpty || fundCode.isEmpty) { save() }
            .onChange(of: fundHouse) { _, newValue in
                showCustomFundHouse = newValue == "Other"
            }
        }
    }

    private func save() {
        let nav = Decimal(string: navPrice) ?? 0
        let scheme = MutualFundScheme(
            schemeName: schemeName,
            fundCode: fundCode,
            fundHouse: showCustomFundHouse ? customFundHouse : (fundHouse.isEmpty ? nil : fundHouse),
            navPrice: nav
        )
        modelContext.insert(scheme)
        try? modelContext.save()
        dismiss()
    }
}
