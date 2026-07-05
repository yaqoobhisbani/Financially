import SwiftUI

struct AccountPickerButton: View {
    let label: String
    let accountName: String?
    var placeholder: String = "Select account"
    let isOutside: Bool
    let action: () -> Void

    init(label: String, accountName: String?, placeholder: String = "Select account", isOutside: Bool = false, action: @escaping () -> Void) {
        self.label = label
        self.accountName = accountName
        self.placeholder = placeholder
        self.isOutside = isOutside
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack {
                Text(label)
                Spacer()
                if isOutside {
                    HStack(spacing: 6) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.tertiarySystemFill))
                                .frame(width: 36, height: 36)
                            Image(systemName: "door.left.hand.open")
                                .foregroundStyle(.secondary)
                        }
                        Text(placeholder)
                    }
                        .foregroundStyle(.secondary)
                } else if let accountName {
                    Text(accountName)
                        .foregroundStyle(.primary)
                } else {
                    Text(placeholder)
                        .foregroundStyle(.secondary)
                }
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
