//
//  RecurrencePickerView.swift
//  DevHours
//
//  Created on 12/26/24.
//

import SwiftUI

struct RecurrencePickerView: View {
    @Binding var frequency: RecurrenceFrequency?
    @Binding var endDate: Date?

    @State private var hasEndDate: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Frequency picker
            Picker("Repeat", selection: $frequency) {
                Text("Never").tag(nil as RecurrenceFrequency?)

                ForEach(RecurrenceFrequency.allCases, id: \.self) { freq in
                    Text(freq.displayName).tag(freq as RecurrenceFrequency?)
                }
            }

            // End date options (only show when recurrence is enabled)
            if frequency != nil {
                Toggle("Has End Date", isOn: $hasEndDate)
                    .onChange(of: hasEndDate) { _, newValue in
                        if !newValue {
                            endDate = nil
                        } else if endDate == nil {
                            // Default to 3 months from now
                            endDate = Calendar.current.date(byAdding: .month, value: 3, to: Date.now)
                        }
                    }

                if hasEndDate, let binding = Binding($endDate) {
                    DatePicker(
                        "End Date",
                        selection: binding,
                        in: Date.now...,
                        displayedComponents: .date
                    )
                }
            }
        }
        .onAppear {
            hasEndDate = endDate != nil
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var frequency: RecurrenceFrequency? = nil
        @State private var endDate: Date? = nil

        var body: some View {
            Form {
                RecurrencePickerView(frequency: $frequency, endDate: $endDate)
            }
        }
    }

    return PreviewWrapper()
}
