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
    case committeeContribution
    case committeePayout
    case commodityBuy
    case commoditySell
    case stockBuy
    case stockSell
    case mutualFundBuy
    case mutualFundSell
}

extension TransactionType: @retroactive CaseIterable {
    public static var allCases: [TransactionType] {
        [.income, .expense, .transfer, .loanGiven, .loanRepayment, .liabilityReceived, .liabilityPayback, .investmentWithdrawal, .investmentAddCapital, .investmentProfitLoss, .committeeContribution, .committeePayout, .commodityBuy, .commoditySell, .stockBuy, .stockSell, .mutualFundBuy, .mutualFundSell]
    }
}