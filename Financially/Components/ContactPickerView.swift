import SwiftUI
import Contacts

struct ContactPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var contacts: [CNContact] = []
    @State private var searchText = ""
    @State private var isLoading = true
    @State private var denied = false
    let onSelect: (String, String?, String?) -> Void

    var filteredContacts: [CNContact] {
        if searchText.isEmpty { return contacts }
        return contacts.filter {
            $0.givenName.localizedCaseInsensitiveContains(searchText) ||
            $0.familyName.localizedCaseInsensitiveContains(searchText) ||
            $0.phoneNumbers.first?.value.stringValue.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if denied {
                    VStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.badge.exclamationmark")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("Contacts access denied")
                            .font(.title3.bold())
                        Text("Enable contacts access in Settings to import contacts.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if isLoading {
                    ProgressView("Loading contacts...")
                } else if filteredContacts.isEmpty {
                    ContentUnavailableView("No Contacts", systemImage: "person.crop.circle.fill", description: Text(searchText.isEmpty ? "No contacts found" : "No matches for \"\(searchText)\""))
                } else {
                    List(filteredContacts, id: \.identifier) { contact in
HStack {
                        VStack(alignment: .leading) {
                            Text("\(contact.givenName) \(contact.familyName)")
                                .font(.headline)
                            if let phone = contact.phoneNumbers.first?.value.stringValue {
                                Text(phone)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if let email = contact.emailAddresses.first?.value {
                                Text(email as String)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        let name = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
                        let phone = contact.phoneNumbers.first?.value.stringValue
                        let email = contact.emailAddresses.first?.value as String?
                        onSelect(name, phone, email)
                        dismiss()
                    }
                    }
                }
            }
            .navigationTitle("Choose Contact")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, placement: .navigationBarDrawer)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task { await loadContacts() }
        }
    }

    private func loadContacts() async {
        let store = CNContactStore()
        let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey, CNContactEmailAddressesKey]

        let status = CNContactStore.authorizationStatus(for: .contacts)
        switch status {
        case .authorized:
            break
        case .notDetermined:
            do {
                let granted = try await store.requestAccess(for: .contacts)
                guard granted else { denied = true; isLoading = false; return }
            } catch {
                denied = true
                isLoading = false
                return
            }
        case .denied, .restricted:
            denied = true
            isLoading = false
            return
        @unknown default:
            denied = true
            isLoading = false
            return
        }

        do {
            let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
            var result: [CNContact] = []
            try store.enumerateContacts(with: request) { contact, _ in
                result.append(contact)
            }
            contacts = result.sorted { $0.givenName < $1.givenName }
        } catch {
            denied = true
        }
        isLoading = false
    }
}