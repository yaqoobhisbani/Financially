import Foundation
import LocalAuthentication

@Observable
final class BiometricAuthManager {
    static let shared = BiometricAuthManager()

    var isAuthenticated = false
    var isProcessing = false
    var errorMessage: String?
    var biometricType: BiometricType = .none

    var biometricEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "biometricEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "biometricEnabled") }
    }

    private init() {}

    func checkAvailability() {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            biometricType = .none
            return
        }
        biometricType = biometricType(from: context.biometryType)
    }

    func authenticate() async {
        let context = LAContext()
        context.localizedFallbackTitle = ""
        context.localizedCancelTitle = "Cancel"

        isProcessing = true
        errorMessage = nil

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Unlock Financially to access your financial data"
            )
            if success {
                isAuthenticated = true
            }
            isProcessing = false
        } catch let error as LAError {
            isProcessing = false
            switch error.code {
            case .biometryNotAvailable:
                errorMessage = "Biometrics not available"
            case .biometryLockout:
                errorMessage = "Biometrics locked. Use passcode to enable."
                biometricEnabled = false
            case .userCancel:
                errorMessage = nil
            case .authenticationFailed:
                errorMessage = "Authentication failed"
            default:
                errorMessage = error.localizedDescription
            }
        } catch {
            isProcessing = false
            errorMessage = error.localizedDescription
        }
    }

    func lock() {
        isAuthenticated = false
    }

    @MainActor
    static func authenticateForIntent() async throws {
        guard shared.biometricEnabled else { return }
        let context = LAContext()
        context.localizedFallbackTitle = ""
        let success = try await context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: "Authenticate to perform this action"
        )
        if !success {
            throw AuthError.cancelled
        }
    }

    enum AuthError: Error {
        case cancelled
    }

    private func biometricType(from type: LABiometryType) -> BiometricType {
        switch type {
        case .faceID: return .faceID
        case .touchID: return .touchID
        case .opticID: return .opticID
        default: return .none
        }
    }
}

enum BiometricType {
    case faceID
    case touchID
    case opticID
    case none

    var displayName: String {
        switch self {
        case .faceID: return "Face ID"
        case .touchID: return "Touch ID"
        case .opticID: return "Optic ID"
        case .none: return "None"
        }
    }

    var icon: String {
        switch self {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .opticID: return "opticid"
        case .none: return "lock.shield"
        }
    }
}