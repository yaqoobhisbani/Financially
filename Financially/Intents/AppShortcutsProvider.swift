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
        AppShortcut(
            intent: PayContributionIntent(),
            phrases: [
                "Pay committee contribution with ${applicationName}",
                "Pay contribution for $committee with ${applicationName}",
            ],
            shortTitle: "Pay Contribution",
            systemImageName: "person.3.fill"
        )
        AppShortcut(
            intent: ReceivePayoutIntent(),
            phrases: [
                "Receive committee payout with ${applicationName}",
                "Receive payout from $committee with ${applicationName}",
            ],
            shortTitle: "Receive Payout",
            systemImageName: "person.3"
        )
        AppShortcut(
            intent: RecordRepaymentIntent(),
            phrases: [
                "Record repayment of $amount from $debtor with ${applicationName}",
                "Record a repayment with ${applicationName}",
            ],
            shortTitle: "Record Repayment",
            systemImageName: "arrow.left.circle.fill"
        )
        AppShortcut(
            intent: PayBackIntent(),
            phrases: [
                "Pay back $amount to $creditor with ${applicationName}",
                "Pay back a creditor with ${applicationName}",
            ],
            shortTitle: "Pay Back Creditor",
            systemImageName: "arrow.right.circle.fill"
        )
        AppShortcut(
            intent: GetDashboardSummaryIntent(),
            phrases: [
                "What is my net worth with ${applicationName}",
                "Show my dashboard with ${applicationName}",
                "Get financial summary with ${applicationName}",
                "How are my finances with ${applicationName}",
            ],
            shortTitle: "Dashboard Summary",
            systemImageName: "rectangle.grid.1x2.fill"
        )
    }
}
