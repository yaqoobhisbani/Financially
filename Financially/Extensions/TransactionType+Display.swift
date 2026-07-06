import SwiftUI

extension TransactionType {
    var displayLabel: String {
        switch self {
        case .income: return "Income"
        case .expense: return "Expense"
        case .transfer: return "Transfer"
        case .loanGiven: return "Loan Given"
        case .loanRepayment: return "Repayment"
        case .liabilityReceived: return "Received"
        case .liabilityPayback: return "Payback"
        case .investmentWithdrawal: return "Withdrawal"
        case .investmentAddCapital: return "Add Capital"
        case .investmentProfitLoss: return "P&L"
        case .committeeContribution: return "Committee"
        case .committeePayout: return "Committee Payout"
        case .commodityBuy: return "Buy Commodity"
        case .commoditySell: return "Sell Commodity"
        case .stockBuy: return "Buy Stock"
        case .stockSell: return "Sell Stock"
        }
    }

    var icon: String {
        switch self {
        case .income: return "arrow.down.circle"
        case .expense: return "arrow.up.circle"
        case .transfer: return "arrow.left.arrow.right"
        case .loanGiven: return "arrow.right.circle"
        case .loanRepayment: return "arrow.left.circle"
        case .liabilityReceived: return "arrow.down.circle"
        case .liabilityPayback: return "arrow.up.circle"
        case .investmentWithdrawal: return "arrow.up.right.circle"
        case .investmentAddCapital: return "plus.circle"
        case .investmentProfitLoss: return "chart.line.uptrend.xyaxis"
        case .committeeContribution: return "person.2.fill"
        case .committeePayout: return "person.2.wave.2.fill"
        case .commodityBuy: return "shippingbox"
        case .commoditySell: return "shippingbox"
        case .stockBuy: return "chart.bar.fill"
        case .stockSell: return "chart.bar.fill"
        }
    }

    var color: Color {
        switch self {
        case .income, .loanRepayment, .liabilityReceived: return .incomeGreen
        case .expense, .loanGiven, .liabilityPayback: return .expenseRed
        case .transfer, .investmentAddCapital: return .blue
        case .investmentWithdrawal: return .orange
        case .investmentProfitLoss: return .purple
        case .committeeContribution: return .orange
        case .committeePayout: return .green
        case .commodityBuy: return .brown
        case .commoditySell: return .brown
        case .stockBuy: return .blue
        case .stockSell: return .blue
        }
    }

    var amountColor: Color {
        switch self {
        case .income, .loanRepayment, .liabilityReceived, .committeePayout: return .incomeGreen
        case .commoditySell: return .incomeGreen
        case .stockSell: return .incomeGreen
        default: return .expenseRed
        }
    }
}
