import SwiftUI

struct CreateCommitteeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var monthlyAmount = ""
    @State private var totalMembers = ""
    @State private var startMonth = Date()
    @State private var hasCyclePosition = false
    @State private var cyclePosition = ""
    @State private var errorMessage: String?

    private var vm: CommitteeViewModel {
        CommitteeViewModel(modelContext: modelContext)
    }

    private var elapsedMonths: Int {
        let calendar = Calendar.current
        let start = calendar.dateComponents([.year, .month], from: startMonth)
        let now = calendar.dateComponents([.year, .month], from: Date())
        let total = (now.year! - start.year!) * 12 + (now.month! - start.month!)
        return max(0, total)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Committee Details") {
                    HStack {
                        Text("Name")
                        Spacer()
                        TextField("e.g. Society 2026", text: $name)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Monthly Amount")
                        Spacer()
                        AmountField(amount: $monthlyAmount)
                    }
                    HStack {
                        Text("Total Members")
                        Spacer()
                        TextField("e.g. 10", text: $totalMembers)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section("Start Month") {
                    DatePicker("Start", selection: $startMonth, displayedComponents: .date)
                }

                if elapsedMonths > 0 {
                    Section {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.blue)
                            Text("\(elapsedMonths) month\(elapsedMonths == 1 ? "" : "s") will be auto-completed as already progressed.")
                        }
                        .font(.subheadline)
                    }
                }

                Section("My Cycle Position") {
                    Toggle("Set my slot", isOn: $hasCyclePosition)
                    if hasCyclePosition {
                        HStack {
                            Text("I am member #")
                            Spacer()
                            TextField("e.g. 3", text: $cyclePosition)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                        }
                    }
                }

                Section {
                    if let members = Int(totalMembers), let amount = Decimal(string: monthlyAmount), members > 0 {
                        HStack {
                            Text("Total Payout")
                            Spacer()
                            Text((amount * Decimal(members)).formattedCurrency())
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                FormErrorSection(message: errorMessage)
            }
            .navigationTitle("New Committee")
            .navigationBarTitleDisplayMode(.inline)
            .formToolbar(label: "Create", isDisabled: name.isEmpty || monthlyAmount.isEmpty || totalMembers.isEmpty) { save() }
        }
    }

    private func save() {
        guard let amount = Decimal(string: monthlyAmount), amount > 0 else {
            errorMessage = "Invalid monthly amount"
            return
        }
        guard let members = Int(totalMembers), members > 1 else {
            errorMessage = "Must have at least 2 members"
            return
        }
        let position: Int?
        if hasCyclePosition, let pos = Int(cyclePosition), pos > 0, pos <= members {
            position = pos
        } else {
            position = nil
        }
        vm.createCommittee(name: name, monthlyAmount: amount, totalMembers: members, startMonth: startMonth, cyclePosition: position, monthsCompleted: elapsedMonths)
        dismiss()
    }
}
