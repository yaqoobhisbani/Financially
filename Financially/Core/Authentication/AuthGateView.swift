import SwiftUI

struct AuthGateView<Content: View>: View {
    @Environment(BiometricAuthManager.self) private var authManager
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        Group {
            if authManager.isAuthenticated || !authManager.biometricEnabled {
                content
            } else {
                VStack(spacing: 24) {
                    Image(systemName: authManager.biometricType.icon)
                        .font(.system(size: 64))
                        .foregroundStyle(.tint)

                    Text("Financially")
                        .font(.largeTitle.bold())

                    Text("Your financial data is protected")
                        .foregroundStyle(.secondary)

                    if let error = authManager.errorMessage {
                        Text(error)
                            .font(.callout)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }

                    if authManager.isProcessing {
                        ProgressView()
                            .controlSize(.large)
                    } else {
                        Button {
                            Task { await authManager.authenticate() }
                        } label: {
                            Label(
                                "Unlock with \(authManager.biometricType.displayName)",
                                systemImage: authManager.biometricType.icon
                            )
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }
                .padding()
                .onAppear {
                    if authManager.biometricEnabled {
                        Task { await authManager.authenticate() }
                    }
                }
            }
        }
    }
}