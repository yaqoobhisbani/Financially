import Foundation

enum AccountType: String, Codable, CaseIterable {
    case bank
    case cash
    case psx
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