import SwiftUI

struct QuickActionItem: Identifiable {
    var id: String { title }
    let title: String
    let systemImage: String
    let tint: Color
    let action: () -> Void
}

struct QuickActionSection: Identifiable {
    var id: String { title }
    let title: String
    let items: [QuickActionItem]
}

/// The resizable command sheet behind the Dashboard's "+" — a grouped grid that
/// scales to any number of actions without a redesign, unlike a fixed menu.
struct QuickActionsSheetContent: View {
    let sections: [QuickActionSection]

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSpacing.xl) {
                    ForEach(sections) { section in
                        VStack(alignment: .leading, spacing: DesignSpacing.sm) {
                            Text(section.title.uppercased())
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)

                            LazyVGrid(columns: columns, spacing: DesignSpacing.sm) {
                                ForEach(section.items) { item in
                                    QuickActionTile(item: item)
                                }
                            }
                        }
                    }
                }
                .padding(DesignSpacing.lg)
            }
            .navigationTitle("Quick Actions")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct QuickActionTile: View {
    let item: QuickActionItem

    var body: some View {
        Button(action: item.action) {
            VStack(spacing: 8) {
                Image(systemName: item.systemImage)
                    .font(.title3)
                    .foregroundStyle(item.tint)
                    .frame(width: 40, height: 40)
                    .background(item.tint.opacity(0.15), in: RoundedRectangle(cornerRadius: DesignRadius.control, style: .continuous))

                Text(item.title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 4)
        }
        .buttonStyle(.plain)
        .dataCard(radius: DesignRadius.control)
    }
}
