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
            intent: BuySharesIntent(),
            phrases: [
                "Buy $shares shares of $stock with ${applicationName}",
                "Buy shares with ${applicationName}",
            ],
            shortTitle: "Buy Shares",
            systemImageName: "chart.line.uptrend.xyaxis"
        )
        AppShortcut(
            intent: SellSharesIntent(),
            phrases: [
                "Sell $shares shares of $stock with ${applicationName}",
                "Sell shares with ${applicationName}",
            ],
            shortTitle: "Sell Shares",
            systemImageName: "chart.line.downtrend.xyaxis"
        )
        AppShortcut(
            intent: InvestMFIntent(),
            phrases: [
                "Invest $units units in $scheme with ${applicationName}",
                "Invest in mutual fund with ${applicationName}",
            ],
            shortTitle: "Invest MF",
            systemImageName: "leaf.fill"
        )
        AppShortcut(
            intent: BuyCommodityIntent(),
            phrases: [
                "Buy $grams grams of $commodity with ${applicationName}",
                "Buy commodity with ${applicationName}",
            ],
            shortTitle: "Buy Commodity",
            systemImageName: "cube.box.fill"
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
    }
}
