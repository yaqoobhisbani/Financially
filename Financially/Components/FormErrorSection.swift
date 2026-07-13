import SwiftUI

struct FormErrorSection: View {
    let message: String?

    var body: some View {
        if let message {
            Section {
                Label {
                    Text(message)
                        .font(.subheadline)
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                }
                .foregroundStyle(.loss)
                .listRowBackground(Color.loss.opacity(0.12))
            }
        }
    }
}
