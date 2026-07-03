import SwiftUI

struct EmptyStateView: View {
    let title: String
    let systemImage: String
    let description: Text?

    init(title: String, systemImage: String, description: String? = nil) {
        self.title = title
        self.systemImage = systemImage
        self.description = description.map(Text.init)
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
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}