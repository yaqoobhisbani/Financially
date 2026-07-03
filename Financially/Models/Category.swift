import Foundation
import SwiftData

@Model
final class Category {
    @Attribute(.unique) var id: UUID
    var name: String
    var icon: String
    var categoryType: CategoryType
    var sortOrder: Int
    var isDefault: Bool

    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        categoryType: CategoryType,
        sortOrder: Int = 0,
        isDefault: Bool = false
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.categoryType = categoryType
        self.sortOrder = sortOrder
        self.isDefault = isDefault
    }
}

enum CategoryType: String, Codable {
    case expense
    case income
}