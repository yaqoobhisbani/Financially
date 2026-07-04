import SwiftUI

struct FormToolbar: ViewModifier {
    let label: String
    let action: () -> Void
    var isDisabled: Bool = false

    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(label) { action() }
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
