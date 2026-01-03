//
//  EntryRow.swift
//  DevHours
//
//  Created on 12/14/24.
//

import SwiftUI

struct EntryRow: View {
    let entry: TimeEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Date badge, Title, and Duration Badge
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    // Date badge
                    Text(formatDate(entry.startTime))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)

                    Text(entry.title.isEmpty ? "Untitled Entry" : entry.title)
                        .font(.headline)
                        .foregroundStyle(entry.title.isEmpty ? .secondary : .primary)

                    // Time range
                    Text(formatTimeRange())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Duration badge with running indicator
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.caption)
                    Text(DurationFormatter.formatHoursMinutes(entry.duration))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.accentColor.opacity(0.15))
                )
                .foregroundStyle(Color.accentColor)
                .opacity(entry.endTime == nil ? 0.8 : 1.0)
                .animation(
                    entry.endTime == nil ?
                        .easeInOut(duration: 1.0).repeatForever(autoreverses: true) :
                        .default,
                    value: entry.endTime
                )
            }

            // Client/Project tag (if available)
            if let client = entry.client {
                HStack(spacing: 6) {
                    Image(systemName: "building.2.fill")
                        .font(.caption2)
                    Text(client.name)
                        .font(.subheadline)

                    if let project = entry.project {
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                        Text(project.name)
                            .font(.subheadline)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.tertiarySystemBackground)
                )
                .foregroundStyle(.secondary)
            }

            // Tags (if any)
            if !entry.tags.isEmpty {
                TagsFlowView(tags: entry.tags)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.systemBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.separatorColor.opacity(0.5), lineWidth: 0.5)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(formatDate(entry.startTime)), \(entry.title.isEmpty ? "Untitled Entry" : entry.title), \(DurationFormatter.formatAccessible(entry.duration))")
    }

    private func formatDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE, MMM d"
            return formatter.string(from: date)
        }
    }

    private func formatTimeRange() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short

        let start = formatter.string(from: entry.startTime)
        if let end = entry.endTime {
            return "\(start) - \(formatter.string(from: end))"
        } else {
            return "\(start) - Now"
        }
    }
}
