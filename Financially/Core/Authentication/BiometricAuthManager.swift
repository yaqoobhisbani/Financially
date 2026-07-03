import Foundation
import LocalAuthentication

@Observable
final class BiometricAuthManager {
    private var context = LAContext()
    private let reason = "Unlock Financially to access your financial data"

    var isAuthenticated = false
    var biometricsAvailable = false
    var biometricsEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "biometricsEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "biometricsEnabled") }
    }

    init() {
        checkAvailability()
    }

    private func checkAvailability() {
        context = LAContext()
        var error: NSError?
        biometricsAvailable = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    func authenticate() async -> Bool {
        guard biometricsEnabled && biometricsAvailable else {
            isAuthenticated = true
            return true
        }

        context = LAContext()

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            isAuthenticated = success
            return success
        } catch {
            isAuthenticated = false
            return false
        }
    }

    func lock() {
        isAuthenticated = false
    }
}