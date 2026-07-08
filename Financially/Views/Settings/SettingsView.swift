import SwiftUI

struct SettingsView: View {
    @AppStorage("colorScheme") private var colorScheme: ColorSchemeOption = .system
    @Environment(BiometricAuthManager.self) private var authManager

    enum ColorSchemeOption: String, CaseIterable {
        case light = "Light"
        case dark = "Dark"
        case system = "System"
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Financial") {
                    NavigationLink(destination: LoansListView()) {
                        Label("Loans & Liabilities", systemImage: "arrow.left.arrow.right")
                    }
                    NavigationLink(destination: ReportsListView()) {
                        Label("Reports", systemImage: "chart.bar.doc.horizontal")
                    }
                }

                Section("Data") {
                    NavigationLink(destination: CategoriesManagementView()) {
                        Label("Categories", systemImage: "list.bullet")
                    }
                    NavigationLink(destination: MarketRatesView()) {
                        Label("Market Rates", systemImage: "chart.line.uptrend.xyaxis")
                    }
                }

                Section {
                    Toggle(isOn: Binding(
                        get: { authManager.biometricEnabled },
                        set: { newValue in
                            if newValue {
                                authManager.biometricEnabled = true
                                authManager.isAuthenticated = false
                                Task { await authManager.authenticate() }
                            } else {
                                authManager.biometricEnabled = false
                                authManager.isAuthenticated = true
                            }
                        }
                    )) {
                        Label(authManager.biometricType.displayName, systemImage: authManager.biometricType.icon)
                    }
                    .disabled(authManager.biometricType == .none)
                } header: {
                    Text("Security")
                } footer: {
                    if authManager.biometricType == .none {
                        Text("Biometrics are not available on this device")
                    } else {
                        Text("Require authentication to access the app")
                    }
                }

                Section("Appearance") {
                    Picker("Theme", selection: $colorScheme) {
                        ForEach(ColorSchemeOption.allCases, id: \.rawValue) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                }

                Section("About") {
                    NavigationLink(destination: AboutView()) {
                        Label("About Financially", systemImage: "info.circle.fill")
                    }
                }
            }
            .navigationTitle("Settings")
            .preferredColorScheme(colorScheme == .system ? nil : colorScheme == .dark ? .dark : .light)
        }
    }

    private func icon(for option: ColorSchemeOption) -> String {
        switch option {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "iphone"
        }
    }
}

struct AboutView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 8) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.tint)
                    Text("Financially")
                        .font(.title.bold())
                    Text("Version 1.0")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }

            Section {
                LabeledContent("Platform", value: "iOS")
                LabeledContent("Architecture", value: "SwiftUI + SwiftData")
            }

            Section {
                Text("Financially is a personal finance management application that combines expense tracking, investment logging, loan management, and liability tracking into a single, unified experience.")
                    .font(.body)
            }
        }
        .navigationTitle("About")
    }
}