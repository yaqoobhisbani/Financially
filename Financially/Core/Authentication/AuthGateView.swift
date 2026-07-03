import SwiftUI

struct AuthGateView<Content: View>: View {
    @Environment(BiometricAuthManager.self) private var authManager
    @State private var hasAttempted = false
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        Group {
            if authManager.isAuthenticated {
                content
            } else {
                VStack(spacing: 24) {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.tint)

                    Text("Financially")
                        .font(.largeTitle.bold())

                    Text("Your financial data is protected")
                        .foregroundStyle(.secondary)

                    if !hasAttempted {
                        ProgressView()
                            .controlSize(.large)
                    } else {
                        Button(action: authenticate) {
                            Label(
                                authManager.biometricsAvailable ? "Unlock with Face ID / Touch ID" : "Enter",
                                systemImage: authManager.biometricsAvailable ? "faceid" : "arrow.right"
                            )
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }
                .padding()
                .onAppear {
                    if !authManager.biometricsEnabled || !authManager.biometricsAvailable {
                        authManager.isAuthenticated = true
                    } else {
                        authenticate()
                    }
                }
            }
        }
    }

    private func authenticate() {
        hasAttempted = true
        Task {
            _ = await authManager.authenticate()
        }
    }
}