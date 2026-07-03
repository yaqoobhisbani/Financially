import SwiftUI

struct DateRangePickerView: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var selectedPreset: DatePreset

    enum DatePreset: String, CaseIterable {
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case thisQuarter = "This Quarter"
        case thisYear = "This Year"
        case custom = "Custom"
    }

    var body: some View {
        VStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(DatePreset.allCases, id: \.rawValue) { preset in
                        Button(preset.rawValue) {
                            applyPreset(preset)
                        }
                        .buttonStyle(.bordered)
                        .tint(selectedPreset == preset ? .accentColor : .gray)
                    }
                }
            }

            if selectedPreset == .custom {
                HStack {
                    DatePicker("From", selection: $startDate, displayedComponents: .date)
                    DatePicker("To", selection: $endDate, displayedComponents: .date)
                }
                .datePickerStyle(.compact)
            }
        }
    }

    private func applyPreset(_ preset: DatePreset) {
        selectedPreset = preset
        let calendar = Calendar.current
        let now = Date()
        switch preset {
        case .thisWeek:
            startDate = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) ?? now
            endDate = now
        case .thisMonth:
            startDate = now.startOfMonth
            endDate = now
        case .thisQuarter:
            let month = calendar.component(.month, from: now)
            let quarterStartMonth = ((month - 1) / 3) * 3 + 1
            startDate = calendar.date(from: DateComponents(year: calendar.component(.year, from: now), month: quarterStartMonth)) ?? now
            endDate = now
        case .thisYear:
            startDate = now.startOfYear
            endDate = now
        case .custom:
            break
        }
    }
}