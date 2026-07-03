import Foundation
import SwiftData

struct SeedCategories {
    static let expenseCategories: [(name: String, icon: String)] = [
        ("Food & Dining", "fork.knife"),
        ("Transportation", "car.fill"),
        ("Shopping", "bag.fill"),
        ("Bills & Utilities", "bolt.fill"),
        ("Entertainment", "tv.fill"),
        ("Health & Medical", "heart.fill"),
        ("Education", "book.fill"),
        ("Groceries", "cart.fill"),
        ("Rent", "house.fill"),
        ("Subscriptions", "repeat"),
        ("Personal Care", "figure.walk"),
        ("Gifts & Donations", "gift.fill"),
        ("Travel", "airplane"),
        ("Other", "ellipsis.circle.fill"),
    ]

    static let incomeCategories: [(name: String, icon: String)] = [
        ("Salary", "dollarsign.circle.fill"),
        ("Freelance", "laptopcomputer"),
        ("Business", "briefcase.fill"),
        ("Rental Income", "house.fill"),
        ("Gift Received", "gift.fill"),
        ("Refund", "arrow.uturn.left.circle.fill"),
        ("Other", "ellipsis.circle.fill"),
    ]

    static func seedIfNeeded(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Category>()
        guard let count = try? modelContext.fetchCount(descriptor), count == 0 else { return }

        for (index, cat) in expenseCategories.enumerated() {
            let category = Category(
                name: cat.name,
                icon: cat.icon,
                categoryType: .expense,
                sortOrder: index,
                isDefault: true
            )
            modelContext.insert(category)
        }

        for (index, cat) in incomeCategories.enumerated() {
            let category = Category(
                name: cat.name,
                icon: cat.icon,
                categoryType: .income,
                sortOrder: index,
                isDefault: true
            )
            modelContext.insert(category)
        }

        try? modelContext.save()
    }
}