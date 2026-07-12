import SwiftUI

struct ThemeSettingsView: View {
    @Environment(ThemeManager.self) private var themeManager
    @AppStorage("colorScheme") private var colorScheme: ColorSchemeOption = .system
    @AppStorage("dashboardGlassCards") private var dashboardGlassCards = false

    enum ColorSchemeOption: String, CaseIterable {
        case light = "Light"
        case dark = "Dark"
        case system = "System"
    }

    private let columns = [GridItem(.adaptive(minimum: 96), spacing: 12)]

    var body: some View {
        List {
            Section("Appearance") {
                ForEach(ColorSchemeOption.allCases, id: \.rawValue) { option in
                    Button {
                        colorScheme = option
                    } label: {
                        HStack {
                            Image(systemName: icon(for: option))
                                .foregroundStyle(.tint)
                            Text(option.rawValue)
                                .foregroundStyle(.primary)
                            Spacer()
                            if colorScheme == option {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                            }
                        }
                    }
                }
            }

            Section {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(AppTheme.all) { theme in
                        Button {
                            themeManager.select(theme)
                        } label: {
                            PreviewChip(
                                gradient: theme.swatchGradient,
                                pattern: themeManager.pattern,
                                label: theme.name,
                                isSelected: theme.id == themeManager.selectedID
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Color")
            } footer: {
                Text("Sets the app's accent color and the dashboard hero gradient.")
            }

            Section {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(HeroPattern.allCases) { pattern in
                        Button {
                            themeManager.select(pattern)
                        } label: {
                            PreviewChip(
                                gradient: themeManager.theme.swatchGradient,
                                pattern: pattern,
                                label: pattern.name,
                                isSelected: pattern == themeManager.pattern
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Dashboard Pattern")
            } footer: {
                Text("The texture drawn over the dashboard hero. Any pattern pairs with any color.")
            }

            Section {
                Toggle(isOn: $dashboardGlassCards) {
                    Label("Glass Dashboard Cards", systemImage: "square.on.square.dashed")
                }
            } footer: {
                Text("Renders the dashboard cards on frosted glass so the hero shows through. Turned off by default; cards stay solid under Reduce Transparency to keep figures legible.")
            }
        }
        .navigationTitle("Theme")
        .preferredColorScheme(colorScheme == .system ? nil : colorScheme == .dark ? .dark : .light)
    }

    private func icon(for option: ColorSchemeOption) -> String {
        switch option {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "iphone"
        }
    }
}

/// A tappable chip previewing a gradient with a pattern overlaid, plus a label. Used for
/// both the color grid (theme gradient + current pattern) and the pattern grid (current
/// theme gradient + that pattern), so each grid previews the live combination.
private struct PreviewChip: View {
    let gradient: LinearGradient
    let pattern: HeroPattern
    let label: String
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                let shape = RoundedRectangle(cornerRadius: DesignRadius.control, style: .continuous)
                shape.fill(gradient)

                HeroPatternView(pattern: pattern, tint: .white)
                    .opacity(0.22)
                    .clipShape(shape)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.25), radius: 2)
                }
            }
            .frame(height: 60)
            .overlay(
                RoundedRectangle(cornerRadius: DesignRadius.control, style: .continuous)
                    .strokeBorder(isSelected ? Color.primary.opacity(0.55) : Color(.separator).opacity(0.4),
                                  lineWidth: isSelected ? 2 : 0.5)
            )

            Text(label)
                .font(.caption)
                .foregroundStyle(isSelected ? .primary : .secondary)
        }
    }
}
