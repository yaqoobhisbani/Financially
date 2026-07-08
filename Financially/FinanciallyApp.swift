import SwiftUI
import SwiftData

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

    var sharedModelContainer: ModelContainer = {
let schema = Schema([
            Account.self,
            Transaction.self,
            LedgerEntry.self,
            Debtor.self,
            Creditor.self,
            InvestmentEntry.self,
            Category.self,
            StockHolding.self,
            StockTrade.self,
            StockInfo.self,
            CommodityInfo.self,
            CommodityHolding.self,
            CommodityTrade.self,
            MutualFundScheme.self,
            MutualFundHolding.self,
            MutualFundTrade.self,
            Committee.self,
            CommitteeContribution.self,
            CommitteePayout.self,
        ])

        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}
