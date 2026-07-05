import SwiftUI

struct CreateCommitteeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var monthlyAmount = ""
    @State private var totalMembers = ""
    @State private var startMonth = Date()
    @State private var hasCyclePosition = false
    @State private var slotPositions: [String] = [""]
    @State private var mySlots = 1
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

    private var members: Int? {
        Int(totalMembers).flatMap { $0 > 1 ? $0 : nil }
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

                Section("My Slots") {
                    Stepper("\(mySlots) slot\(mySlots == 1 ? "" : "s")", value: $mySlots, in: 1...max(members ?? 1, 1))
                }

                Section("My Cycle Position") {
                    Toggle("Set my slot number(s)", isOn: $hasCyclePosition)
                        .onChange(of: hasCyclePosition) { _, on in
                            if on {
                                syncPositionsToSlots()
                            }
                        }
                    if hasCyclePosition {
                        ForEach(0..<slotPositions.count, id: \.self) { index in
                            HStack {
                                Text("Slot \(index + 1) #")
                                Spacer()
                                TextField("member #", text: $slotPositions[index])
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 60)
                            }
                        }
                    }
                }
                .onChange(of: mySlots) { _, _ in
                    if hasCyclePosition {
                        syncPositionsToSlots()
                    }
                }

                Section {
                    if let m = members, let amount = Decimal(string: monthlyAmount), amount > 0 {
                        HStack {
                            Text("Payout per Slot")
                            Spacer()
                            Text((amount * Decimal(m)).formattedCurrency())
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Text("My Total Payout")
                            Spacer()
                            Text((amount * Decimal(m) * Decimal(mySlots)).formattedCurrency())
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

    private func syncPositionsToSlots() {
        while slotPositions.count < mySlots {
            slotPositions.append("")
        }
        if slotPositions.count > mySlots {
            slotPositions = Array(slotPositions.prefix(mySlots))
        }
    }

    private func save() {
        guard let amount = Decimal(string: monthlyAmount), amount > 0 else {
            errorMessage = "Invalid monthly amount"
            return
        }
        guard let totalMembers = members else {
            errorMessage = "Must have at least 2 members"
            return
        }
        let positionsString: String?
        if hasCyclePosition {
            let valid = slotPositions.compactMap { Int($0) }.filter { $0 >= 1 && $0 <= totalMembers }
            positionsString = valid.isEmpty ? nil : valid.map(String.init).joined(separator: ",")
        } else {
            positionsString = nil
        }
        vm.createCommittee(name: name, monthlyAmount: amount, totalMembers: totalMembers, startMonth: startMonth, cyclePosition: Int(positionsString?.split(separator: ",").first ?? ""), mySlots: mySlots, mySlotPositions: positionsString, monthsCompleted: elapsedMonths)
        dismiss()
    }
}
