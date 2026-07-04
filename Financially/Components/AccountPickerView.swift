import SwiftUI

struct AccountPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let accounts: [Account]
    let title: String
    let filterType: AccountType?
    let onSelect: (Account) -> Void

    init(accounts: [Account], title: String, filterType: AccountType?, onSelect: @escaping (Account) -> Void) {
        self.accounts = accounts
        self.title = title
        self.filterType = filterType
        self.onSelect = onSelect
    }

    private var filteredAccounts: [Account] {
        let active = accounts.filter { $0.isActive }
        if let filterType = filterType {
            return active.filter { $0.accountType == filterType }
        }
        return active
    }

    var body: some View {
        NavigationStack {
            List(filteredAccounts) { account in
                AccountRowView(account: account, holdings: [])
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelect(account)
                        dismiss()
                    }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}