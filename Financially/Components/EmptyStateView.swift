import SwiftUI

struct EmptyStateView: View {
    let title: String
    let systemImage: String
    let description: Text?
    let buttonLabel: String?
    let action: (() -> Void)?

    init(title: String, systemImage: String, description: String? = nil, buttonLabel: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.systemImage = systemImage
        self.description = description.map(Text.init)
        self.buttonLabel = buttonLabel
        self.action = action
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.title3.bold())

            if let description = description {
                description
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let buttonLabel, let action = action {
                Button(buttonLabel, action: action)
                    .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}