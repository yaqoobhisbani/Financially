import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Appearance") {
                    NavigationLink(destination: ThemeSettingsView()) {
                        Label("Theme", systemImage: "paintpalette.fill")
                    }
                }

                Section("Security") {
                    NavigationLink(destination: SecuritySettingsView()) {
                        Label("Security", systemImage: "lock.fill")
                    }
                }

                Section("Data") {
                    NavigationLink(destination: CategoriesManagementView()) {
                        Label("Categories", systemImage: "list.bullet")
                    }
                }

                Section("About") {
                    NavigationLink(destination: AboutView()) {
                        Label("About Financially", systemImage: "info.circle.fill")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct SecuritySettingsView: View {
    @Environment(BiometricAuthManager.self) private var authManager

    var body: some View {
        List {
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
            } footer: {
                if authManager.biometricType == .none {
                    Text("Biometrics are not available on this device")
                } else {
                    Text("Require authentication to access the app")
                }
            }
        }
        .navigationTitle("Security")
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
                LabeledContent("Platforms", value: "iOS, macOS")
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