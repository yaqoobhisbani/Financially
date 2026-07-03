import SwiftUI
import SwiftData

struct CategoriesManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @State private var showingAdd = false
    @State private var editCategory: Category?

    var body: some View {
        List {
            Section("Expense Categories") {
                ForEach(categories.filter { $0.categoryType == .expense }) { category in
                    HStack {
                        Image(systemName: category.icon)
                            .foregroundStyle(.tint)
                        Text(category.name)
                        Spacer()
                        if category.isDefault {
                            Text("Default")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions {
                        if !category.isDefault {
                            Button("Delete", role: .destructive) {
                                modelContext.delete(category)
                            }
                        }
                    }
                }
            }

            Section("Income Categories") {
                ForEach(categories.filter { $0.categoryType == .income }) { category in
                    HStack {
                        Image(systemName: category.icon)
                            .foregroundStyle(.tint)
                        Text(category.name)
                        Spacer()
                        if category.isDefault {
                            Text("Default")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions {
                        if !category.isDefault {
                            Button("Delete", role: .destructive) {
                                modelContext.delete(category)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Categories")
        .toolbar {
            ToolbarItem {
                Button(action: { showingAdd = true }) {
                    Label("Add", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddCategoryView()
        }
    }
}

struct AddCategoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var icon = "ellipsis.circle.fill"
    @State private var categoryType: CategoryType = .expense

    let commonIcons = ["cart.fill", "fork.knife", "car.fill", "house.fill", "heart.fill", "book.fill", "tv.fill", "gift.fill", "bag.fill", "bolt.fill", "figure.walk", "airplane", "repeat", "laptopcomputer", "briefcase.fill", "dollarsign.circle.fill", "ellipsis.circle.fill"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $name)
                    Picker("Type", selection: $categoryType) {
                        Text("Expense").tag(CategoryType.expense)
                        Text("Income").tag(CategoryType.income)
                    }
                }

                Section("Icon") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 8) {
                        ForEach(commonIcons, id: \.self) { iconName in
                            Button {
                                icon = iconName
                            } label: {
                                Image(systemName: iconName)
                                    .font(.title3)
                                    .foregroundStyle(icon == iconName ? .white : .primary)
                                    .frame(width: 44, height: 44)
                                    .background(icon == iconName ? Color.accentColor : Color.clear)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Category")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let maxOrder = (try? modelContext.fetchCount(FetchDescriptor<Category>())) ?? 0
                        let category = Category(name: name, icon: icon, categoryType: categoryType, sortOrder: maxOrder, isDefault: false)
                        modelContext.insert(category)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}