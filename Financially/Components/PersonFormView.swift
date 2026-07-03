import SwiftUI

struct PersonFormView: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let onSave: (String, String?, String?) -> Void

    @State private var name = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var showContactPicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        TextField("Name", text: $name)
                        Button(action: { showContactPicker = true }) {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.title3)
                                .foregroundStyle(.tint)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section("Contact Info") {
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(
                            name,
                            phone.isEmpty ? nil : phone,
                            email.isEmpty ? nil : email
                        )
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .sheet(isPresented: $showContactPicker) {
                ContactPickerView { contactName, contactPhone, contactEmail in
                    name = contactName
                    phone = contactPhone ?? ""
                    email = contactEmail ?? ""
                }
            }
        }
    }
}