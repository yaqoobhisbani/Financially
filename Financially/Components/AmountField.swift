import SwiftUI

struct AmountField: View {
    @Binding var amount: String
    var label: String = "PKR"
    var suffix: String? = nil

    var body: some View {
        HStack {
            Text(label)
            TextField("0", text: $amount)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
            if let suffix {
                Text(suffix)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
