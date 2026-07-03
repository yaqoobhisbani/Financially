import SwiftUI

struct LoansListView: View {
    @State private var selectedSegment: LoanSegment = .debtors

    enum LoanSegment: String, CaseIterable {
        case debtors = "Debtors"
        case creditors = "Creditors"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Type", selection: $selectedSegment) {
                    ForEach(LoanSegment.allCases, id: \.rawValue) { segment in
                        Text(segment.rawValue).tag(segment)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                if selectedSegment == .debtors {
                    DebtorsListView()
                } else {
                    CreditorsListView()
                }
            }
            .navigationTitle("Loans & Liabilities")
        }
    }
}

#Preview {
    LoansListView()
}