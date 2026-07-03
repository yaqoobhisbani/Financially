import SwiftUI
import SwiftData

@main
struct FinanciallyApp: App {
    @State private var authManager = BiometricAuthManager()
    @State private var cloudKitManager = CloudKitManager()
    @AppStorage("colorScheme") private var colorScheme: String = "System"

    var body: some Scene {
        WindowGroup {
            AuthGateView {
                ContentView()
                    .environment(cloudKitManager)
                    .onAppear {
                        SeedCategories.seedIfNeeded(modelContext: sharedModelContainer.mainContext)
                        Task { await cloudKitManager.setup() }
                    }
            }
            .environment(authManager)
            .preferredColorScheme(scheme)
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

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Account.self,
            Transaction.self,
            LedgerEntry.self,
            Debtor.self,
            Creditor.self,
            InvestmentEntry.self,
            Category.self,
        ])

        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}