import SwiftUI

struct FormToolbar: ViewModifier {
    let label: String
    let action: () -> Void
    var isDisabled: Bool = false

    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                }
                .glassIconButton()
                .accessibilityLabel("Cancel")
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(label) { action() }
                    .buttonStyle(.glass)
                    .disabled(isDisabled)
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
}

extension View {
    func formToolbar(label: String, isDisabled: Bool = false, action: @escaping () -> Void) -> some View {
        modifier(FormToolbar(label: label, action: action, isDisabled: isDisabled))
    }
}
