//
//  EntryRow.swift
//  DevHours
//
//  Created on 12/14/24.
//

import SwiftUI

struct EntryRow: View {
    let entry: TimeEntry

    /// Accent color based on tag color or title hash for visual variety
    private var accentColor: Color {
        // Priority 1: Use first tag's color
        if let tags = entry.tags, let firstTag = tags.first {
            return Color.fromHex(firstTag.colorHex)
        }
        // Priority 2: Deterministic color from title hash
        let hash = abs(entry.title.hashValue)
        let colorIndex = hash % TagColors.presets.count
        return Color.fromHex(TagColors.presets[colorIndex].hex)
    }

    /// Whether this entry is currently running
    private var isRunning: Bool {
        entry.endTime == nil
    }

    var body: some View {
        HStack(spacing: 0) {
            // Color accent bar
            Rectangle()
                .fill(accentColor)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 12) {
                // Header: Title and Duration Badge
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
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
                            .fill(accentColor.opacity(0.15))
                    )
                    .foregroundStyle(accentColor)
                    .opacity(isRunning ? 0.8 : 1.0)
                    .animation(
                        isRunning ?
                            .easeInOut(duration: 1.0).repeatForever(autoreverses: true) :
                            .default,
                        value: isRunning
                    )
                }

                // Client tag (if available)
                if let client = entry.client {
                    HStack(spacing: 6) {
                        Image(systemName: "building.2.fill")
                            .font(.caption2)
                        Text(client.name)
                            .font(.subheadline)
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
                let tags = entry.tags ?? []
                if !tags.isEmpty {
                    TagsFlowView(tags: tags)
                }
            }
            .padding(16)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isRunning ? Color.green.opacity(0.03) : Color.systemBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.separatorColor.opacity(0.5), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.title.isEmpty ? "Untitled Entry" : entry.title), \(formatTimeRange()), \(DurationFormatter.formatAccessible(entry.duration))")
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
