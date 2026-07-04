import SwiftUI

struct FormErrorSection: View {
    let message: String?

    var body: some View {
        if let message {
            Section {
                Text(message)
                    .foregroundStyle(.red)
            }
        }
    }
}
