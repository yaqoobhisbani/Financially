import SwiftUI

struct AuthGateView<Content: View>: View {
    @Environment(BiometricAuthManager.self) private var authManager
    @Environment(ThemeManager.self) private var themeManager
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        Group {
            if authManager.isAuthenticated || !authManager.biometricEnabled {
                content
            } else {
                ZStack {
                    LinearGradient(
                        colors: [themeManager.theme.accent, themeManager.theme.accent.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()

                    VStack(spacing: 28) {
                        Spacer()

                        VStack(spacing: 12) {
                            Image(systemName: authManager.biometricType.icon)
                                .font(.system(size: 60))
                                .foregroundStyle(.white)

                            Text("Financially")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)

                            Text("Your financial data is protected")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.8))
                        }

                        if let error = authManager.errorMessage {
                            Label(error, systemImage: "exclamationmark.triangle.fill")
                                .font(.subheadline)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(.white.opacity(0.16), in: Capsule())
                        }

                        Spacer()

                        if authManager.isProcessing {
                            ProgressView()
                                .tint(.white)
                                .controlSize(.large)
                        } else {
                            Button {
                                Task { await authManager.authenticate() }
                            } label: {
                                Label(
                                    "Unlock with \(authManager.biometricType.displayName)",
                                    systemImage: authManager.biometricType.icon
                                )
                                .foregroundStyle(themeManager.theme.accent)
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.glass)
                            .controlSize(.large)
                            .padding(.horizontal, 32)
                        }
                    }
                    .padding(.vertical, 48)
                }
                .onAppear {
                    if authManager.biometricEnabled {
                        Task { await authManager.authenticate() }
                    }
                }
            }
        }
    }
}