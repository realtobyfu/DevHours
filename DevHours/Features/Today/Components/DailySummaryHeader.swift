//
//  DailySummaryHeader.swift
//  DevHours
//
//  Created on 12/13/24.
//

import SwiftUI

struct DailySummaryHeader: View {
    let totalDuration: TimeInterval
    let entryCount: Int

    var body: some View {
        HStack(spacing: 20) {
            // Total time today
            VStack(alignment: .leading, spacing: 4) {
                Text("Total Today")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                Text(DurationFormatter.formatHoursMinutes(totalDuration))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
            }

            Spacer()

            // Entry count
            HStack(spacing: 6) {
                Image(systemName: "list.bullet.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(entryCount)")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text(entryCount == 1 ? "entry" : "entries")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondarySystemBackground)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Total today: \(DurationFormatter.formatAccessible(totalDuration)), \(entryCount) \(entryCount == 1 ? "entry" : "entries")")
    }
}
