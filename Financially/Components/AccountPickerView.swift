import SwiftUI

struct AccountPickerView: View {
    @Environment(\.dismiss) private var dismiss
    let accounts: [Account]
    let title: String
    let filterType: AccountType?
    let showNoneOption: Bool
    let onSelect: (Account?) -> Void

    init(accounts: [Account], title: String, filterType: AccountType?, onSelect: @escaping (Account?) -> Void, showNoneOption: Bool = false) {
        self.accounts = accounts
        self.title = title
        self.filterType = filterType
        self.showNoneOption = showNoneOption
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
            List {
                if showNoneOption {
                    Button {
                        onSelect(nil)
                        dismiss()
                    } label: {
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.tertiarySystemFill))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "door.left.hand.open")
                                    .foregroundStyle(.secondary)
                            }
                            Text("None — Outside")
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }

                ForEach(filteredAccounts) { account in
                    AccountRowView(account: account, holdings: [])
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onSelect(account)
                            dismiss()
                        }
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