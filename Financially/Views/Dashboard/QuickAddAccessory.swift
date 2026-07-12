import SwiftUI

/// The "Quick Add" handle that lives in the tab view's bottom accessory slot,
/// just above the glass tab bar. Tap or drag it up to open the quick-actions
/// command sheet. Adapts to the system-driven inline/expanded placement.
struct QuickAddAccessory: View {
    let onOpen: () -> Void

    @Environment(\.tabViewBottomAccessoryPlacement) private var placement
    @Environment(ThemeManager.self) private var themeManager

    var body: some View {
        Button(action: onOpen) {
            if placement == .inline {
                // Minimized tab bar: compact icon-only affordance.
                Image(systemName: "plus")
                    .font(.headline)
                    .foregroundStyle(themeManager.theme.accent)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "plus")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(themeManager.theme.accent, in: Circle())

                    Text("Quick Add")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.up")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Quick Add")
        .accessibilityHint("Opens quick actions")
        .highPriorityGesture(
            DragGesture(minimumDistance: 6)
                .onEnded { value in
                    if value.translation.height < -8 { onOpen() }
                }
        )
    }
}
