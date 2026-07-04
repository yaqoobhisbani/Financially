import SwiftUI

struct PercentageText: View {
    let value: Decimal
    var body: some View {
        Text(value.formatted(.number.precision(.fractionLength(2))) + "%")
    }
}
