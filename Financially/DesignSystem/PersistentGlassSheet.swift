import SwiftUI

/// The Apple Maps pattern: a resizable sheet that floats as Liquid Glass while small
/// and turns into an opaque full-screen surface at `.large`. The content behind stays
/// interactive up through `interactiveUpThrough`, so a chart or dashboard beneath the
/// sheet can still be scrubbed/tapped at the peek and half detents.
extension View {
    func persistentGlassSheet<SheetContent: View>(
        isPresented: Binding<Bool>,
        detents: Set<PresentationDetent> = [.height(112), .medium, .large],
        selection: Binding<PresentationDetent>? = nil,
        interactiveUpThrough: PresentationDetent = .medium,
        dismissible: Bool = true,
        @ViewBuilder content: @escaping () -> SheetContent
    ) -> some View {
        sheet(isPresented: isPresented) {
            content()
                .modifier(SheetDetentsModifier(detents: detents, selection: selection))
                .presentationBackgroundInteraction(.enabled(upThrough: interactiveUpThrough))
                .presentationContentInteraction(.scrolls)
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled(!dismissible)
        }
    }
}

/// Applies `presentationDetents` with an optional selection binding, so a caller can
/// control which detent the sheet opens at (e.g. open straight to `.medium` on tap).
private struct SheetDetentsModifier: ViewModifier {
    let detents: Set<PresentationDetent>
    let selection: Binding<PresentationDetent>?

    func body(content: Content) -> some View {
        if let selection {
            content.presentationDetents(detents, selection: selection)
        } else {
            content.presentationDetents(detents)
        }
    }
}
