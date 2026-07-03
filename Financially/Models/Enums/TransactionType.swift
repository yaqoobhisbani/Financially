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