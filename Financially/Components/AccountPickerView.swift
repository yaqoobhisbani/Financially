import SwiftUI
import SwiftData

struct AccountPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var accounts: [Account]
    @Query private var allHoldings: [StockHolding]
    let title: String
    let filterType: AccountType?
    let onSelect: (Account) -> Void

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
                AccountRowView(account: account, holdings: allHoldings)
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