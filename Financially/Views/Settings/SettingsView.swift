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
                    NavigationLink(destination: DataSettingsView()) {
                        Label("Data & Sync", systemImage: "arrow.triangle.2.circlepath")
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
                    get: { authManager.biometricsEnabled },
                    set: { authManager.biometricsEnabled = $0 }
                )) {
                    Label(authManager.biometricsAvailable ? "Face ID / Touch ID" : "Biometrics", systemImage: "faceid")
                }
                .disabled(!authManager.biometricsAvailable)
            } footer: {
                if !authManager.biometricsAvailable {
                    Text("Biometrics are not available on this device")
                } else {
                    Text("Require authentication to access the app")
                }
            }
        }
        .navigationTitle("Security")
    }
}

struct DataSettingsView: View {
    var body: some View {
        List {
            Section("Sync") {
                LabeledContent("iCloud", value: "Connected")
                LabeledContent("Last Sync", value: "Just now")
            }

            Section("Storage") {
                LabeledContent("Local Data", value: "Stored on device")
            }

            Section {
                Button("Export Data (Coming Soon)", systemImage: "square.and.arrow.up") {}
                    .foregroundStyle(.secondary)
                Button("Import Data (Coming Soon)", systemImage: "square.and.arrow.down") {}
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Data & Sync")
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
                LabeledContent("Architecture", value: "SwiftUI + SwiftData + CloudKit")
                LabeledContent("Data", value: "End-to-end encrypted via iCloud")
            }

            Section {
                Text("Financially is a personal finance management application that combines expense tracking, investment logging, loan management, and liability tracking into a single, unified experience. All data is synced via CloudKit through your Apple Account.")
                    .font(.body)
            }
        }
        .navigationTitle("About")
    }
}