//
//  TodayEntryRow.swift
//  DevHours
//
//  Created on 12/13/24.
//

import SwiftUI
import SwiftData

struct TodayEntryRow: View {
    @Bindable var entry: TimeEntry
    @FocusState private var isTitleFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Title and Duration Badge
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Untitled Entry", text: $entry.title, axis: .vertical)
                        .font(.headline)
                        .foregroundStyle(entry.title.isEmpty ? .secondary : .primary)
                        .focused($isTitleFocused)
                        .textFieldStyle(.plain)
                        .lineLimit(1...3)

                    // Time range
                    Text(formatTimeRange())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Duration badge
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

            // Tags (if any) - compact style for today view
            if !entry.tags.isEmpty {
                TagsFlowView(tags: entry.tags, compact: true)
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
