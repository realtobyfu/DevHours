//
//  DurationPickerView.swift
//  DevHours
//
//  Created on 12/26/24.
//

import SwiftUI

struct DurationPickerView: View {
    @Binding var duration: TimeInterval
    @State private var isExpanded = false

    private var hours: Int {
        Int(duration) / 3600
    }

    private var minutes: Int {
        (Int(duration) % 3600) / 60
    }

    private var hoursBinding: Binding<Int> {
        Binding(
            get: { hours },
            set: { newHours in
                duration = TimeInterval(newHours * 3600 + minutes * 60)
            }
        )
    }

    private var minutesBinding: Binding<Int> {
        Binding(
            get: { minutes },
            set: { newMinutes in
                duration = TimeInterval(hours * 3600 + newMinutes * 60)
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Estimated Duration")
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            DisclosureGroup(isExpanded: $isExpanded) {
                HStack(spacing: 0) {
                    Picker("Hours", selection: hoursBinding) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text("\(hour) hr").tag(hour)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 100)
                    .clipped()

                    Picker("Minutes", selection: minutesBinding) {
                        ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) { minute in
                            Text("\(minute) min").tag(minute)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 100)
                    .clipped()
                }
                .frame(height: 120)
            } label: {
                Text(DurationFormatter.formatHoursMinutes(duration))
                    .font(.body)
            }
            .accessibilityLabel("Duration picker, currently \(DurationFormatter.formatHoursMinutes(duration))")
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var duration: TimeInterval = 3600

        var body: some View {
            DurationPickerView(duration: $duration)
                .padding()
        }
    }

    return PreviewWrapper()
}
