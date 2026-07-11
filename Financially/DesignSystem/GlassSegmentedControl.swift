import SwiftUI

/// A glass-track segmented control: the outer capsule is real Liquid Glass chrome,
/// the selected segment is an opaque pill that slides between options — chrome floats,
/// content (the selection indicator) stays solid.
struct GlassSegmentedControl<Option: Hashable>: View {
    let options: [Option]
    @Binding var selection: Option
    let title: (Option) -> String

    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options, id: \.self) { option in
                Text(title(option))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(selection == option ? Color.primary : Color.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.vertical, 7)
                    .frame(maxWidth: .infinity)
                    .background {
                        if selection == option {
                            Capsule()
                                .fill(Color(.secondarySystemGroupedBackground))
                                .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                                .matchedGeometryEffect(id: "selection", in: namespace)
                        }
                    }
                    .contentShape(Capsule())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.22)) { selection = option }
                    }
            }
        }
        .padding(3)
        .glassChrome(in: Capsule())
    }
}
