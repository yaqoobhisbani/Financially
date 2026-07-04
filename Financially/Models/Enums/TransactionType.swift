import Foundation

enum TransactionType: String, Codable {
    case income
    case expense
    case transfer
    case investmentWithdrawal
    case investmentAddCapital
    case loanGiven
    case loanRepayment
    case liabilityReceived
    case liabilityPayback
    case investmentProfitLoss
}

extension TransactionType: @retroactive CaseIterable {
    public static var allCases: [TransactionType] {
        [.income, .expense, .transfer, .loanGiven, .loanRepayment, .liabilityReceived, .liabilityPayback, .investmentWithdrawal, .investmentAddCapital, .investmentProfitLoss]
    }
}