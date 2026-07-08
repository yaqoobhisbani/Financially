import Foundation

enum AccountType: String, Codable, CaseIterable {
    case bank
    case cash
    case psx
    case mutualFund

    var displayName: String {
        switch self {
        case .bank: return "Bank"
        case .cash: return "Cash"
        case .psx: return "PSX Stock"
        case .mutualFund: return "Mutual Fund"
        }
    }
}

enum BankSubType: String, Codable, CaseIterable {
    case traditional
    case sadaPay
    case nayaPay
    case jazzCash
    case easyPaisa
}

enum CashSubType: String, Codable, CaseIterable {
    case wallet
    case home
    case other
}