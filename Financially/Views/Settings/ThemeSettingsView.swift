import SwiftUI

struct ThemeSettingsView: View {
    @AppStorage("colorScheme") private var colorScheme: ColorSchemeOption = .system

    enum ColorSchemeOption: String, CaseIterable {
        case light = "Light"
        case dark = "Dark"
        case system = "System"
    }

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
                Text("Changes apply immediately")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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

