import Foundation
import AppIntents

struct FinanciallyShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddExpenseIntent(),
            phrases: [
                "Add expense of $amount for $category with ${applicationName}",
                "Record an expense with ${applicationName}",
                "Log expense of $amount in ${applicationName}",
            ],
            shortTitle: "Add Expense",
            systemImageName: "cart.fill"
        )
        AppShortcut(
            intent: AddIncomeIntent(),
            phrases: [
                "Add income of $amount as $category with ${applicationName}",
                "Record income with ${applicationName}",
                "Log income of $amount in ${applicationName}",
            ],
            shortTitle: "Add Income",
            systemImageName: "dollarsign.circle.fill"
        )
        AppShortcut(
            intent: TransferMoneyIntent(),
            phrases: [
                "Transfer $amount from $sourceAccount to $destinationAccount with ${applicationName}",
                "Transfer money with ${applicationName}",
            ],
            shortTitle: "Transfer Money",
            systemImageName: "arrow.left.arrow.right"
        )
        AppShortcut(
            intent: GiveLoanIntent(),
            phrases: [
                "Give loan of $amount to $personName with ${applicationName}",
                "Record a loan with ${applicationName}",
            ],
            shortTitle: "Give Loan",
            systemImageName: "arrow.right.circle"
        )
    }
}
