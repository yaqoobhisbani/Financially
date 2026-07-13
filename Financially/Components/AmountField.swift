import SwiftUI

struct AmountField: View {
    @Binding var amount: String
    var label: String = "PKR"
    var suffix: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            Spacer()
            Text(label)
                .font(.title3.weight(.medium))
                .foregroundStyle(.secondary)
            TextField("0", text: $amount)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .font(.moneyHero)
                .tabularNumbers()
                .fixedSize()
            if let suffix {
                Text(suffix)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 6)
    }
}
