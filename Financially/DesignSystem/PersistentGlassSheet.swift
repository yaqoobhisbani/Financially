import SwiftUI

/// The Apple Maps pattern: a resizable sheet that floats as Liquid Glass while small
/// and turns into an opaque full-screen surface at `.large`. The content behind stays
/// interactive up through `interactiveUpThrough`, so a chart or dashboard beneath the
/// sheet can still be scrubbed/tapped at the peek and half detents.
extension View {
    func persistentGlassSheet<SheetContent: View>(
        isPresented: Binding<Bool>,
        detents: Set<PresentationDetent> = [.height(112), .medium, .large],
        interactiveUpThrough: PresentationDetent = .medium,
        dismissible: Bool = true,
        @ViewBuilder content: @escaping () -> SheetContent
    ) -> some View {
        sheet(isPresented: isPresented) {
            content()
                .presentationDetents(detents)
                .presentationBackgroundInteraction(.enabled(upThrough: interactiveUpThrough))
                .presentationContentInteraction(.scrolls)
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled(!dismissible)
        }
    }
}
