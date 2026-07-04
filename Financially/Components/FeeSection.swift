import SwiftUI

struct FeeSection: View {
    @Binding var brokerageFee: String
    @Binding var tax: String
    let netLabel: String
    let netValue: String?

    var body: some View {
        Section("Fees") {
            HStack {
                Text("Brokerage Fee")
                Spacer()
                TextField("0", text: $brokerageFee)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
            }
            HStack {
                Text("Tax")
                Spacer()
                TextField("0", text: $tax)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
            }
            if let netValue {
                HStack {
                    Text(netLabel)
                    Spacer()
                    Text(netValue)
                        .font(.headline)
                }
            }
        }
    }
}
