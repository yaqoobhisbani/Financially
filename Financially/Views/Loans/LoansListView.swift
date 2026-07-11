import SwiftUI

struct LoansListView: View {
    @State private var selectedSegment: LoanSegment

    enum LoanSegment: String, CaseIterable {
        case debtors = "Debtors"
        case creditors = "Creditors"
    }

    init(initialSegment: LoanSegment = .debtors) {
        _selectedSegment = State(initialValue: initialSegment)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                GlassSegmentedControl(options: LoanSegment.allCases, selection: $selectedSegment) { $0.rawValue }
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