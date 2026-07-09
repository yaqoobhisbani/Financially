import SwiftUI
import SwiftData
import AppIntents

@main
struct FinanciallyApp: App {
    @State private var authManager = BiometricAuthManager.shared
    @AppStorage("colorScheme") private var colorScheme: String = "System"

    var body: some Scene {
        WindowGroup {
            AuthGateView {
                ContentView()
                    .onAppear {
                        let mc = sharedModelContainer.mainContext
                        SeedCategories.seedIfNeeded(modelContext: mc)
                        SeedCategories.seedCommoditiesIfNeeded(modelContext: mc)
                    }
            }
            .environment(authManager)
            .preferredColorScheme(scheme)
            .onAppear {
                authManager.checkAvailability()
            }
        }
        .modelContainer(sharedModelContainer)
    }

    private var scheme: ColorScheme? {
        switch colorScheme {
        case "Dark": return .dark
        case "Light": return .light
        default: return nil
        }
    }

    var sharedModelContainer: ModelContainer { .financially }
}
