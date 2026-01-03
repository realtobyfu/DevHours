//
//  TimerWidget.swift
//  DevHoursWidgets
//
//  Widget showing the current running timer with stop button.
//

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct TimerEntry: TimelineEntry {
    let date: Date
    let isRunning: Bool
    let title: String
    let startTime: Date?
    let relevance: TimelineEntryRelevance?

    var elapsedTime: TimeInterval {
        guard let startTime else { return 0 }
        return date.timeIntervalSince(startTime)
    }

    static var placeholder: TimerEntry {
        TimerEntry(
            date: .now,
            isRunning: true,
            title: "Working on task",
            startTime: Date().addingTimeInterval(-3723), // 1h 2m 3s ago
            relevance: TimelineEntryRelevance(score: 1.0)
        )
    }

    static var notRunning: TimerEntry {
        TimerEntry(
            date: .now,
            isRunning: false,
            title: "",
            startTime: nil,
            relevance: TimelineEntryRelevance(score: 0.2)
        )
    }
}

// MARK: - Timeline Provider

struct TimerTimelineProvider: TimelineProvider {
    private static let appGroupIdentifier = "group.com.tobiasfu.DevHours"
    private static let widgetDataFileName = "widget-tasks.json"

    func placeholder(in context: Context) -> TimerEntry {
        TimerEntry.placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (TimerEntry) -> Void) {
        if context.isPreview {
            completion(TimerEntry.placeholder)
        } else {
            let entry = loadTimerEntry()
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TimerEntry>) -> Void) {
        let timerData = loadTimerData()

        if timerData.isRunning, let startTime = timerData.startTime {
            // Timer is running - create entries for the next hour (one per minute)
            // High relevance for Smart Stack when timer is active
            var entries: [TimerEntry] = []
            let now = Date()
            let runningRelevance = TimelineEntryRelevance(score: 1.0)

            for minuteOffset in 0..<60 {
                let entryDate = now.addingTimeInterval(Double(minuteOffset) * 60)
                entries.append(TimerEntry(
                    date: entryDate,
                    isRunning: true,
                    title: timerData.title ?? "",
                    startTime: startTime,
                    relevance: runningRelevance
                ))
            }

            let timeline = Timeline(entries: entries, policy: .after(now.addingTimeInterval(3600)))
            completion(timeline)
        } else {
            // No timer running - single entry, refresh when data changes
            // Low relevance for Smart Stack when idle
            let entry = TimerEntry.notRunning
            let timeline = Timeline(entries: [entry], policy: .never)
            completion(timeline)
        }
    }

    private func loadTimerEntry() -> TimerEntry {
        let timerData = loadTimerData()
        let relevance = timerData.isRunning
            ? TimelineEntryRelevance(score: 1.0)
            : TimelineEntryRelevance(score: 0.2)
        return TimerEntry(
            date: .now,
            isRunning: timerData.isRunning,
            title: timerData.title ?? "",
            startTime: timerData.startTime,
            relevance: relevance
        )
    }

    private func loadTimerData() -> WidgetTimerData {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Self.appGroupIdentifier
        ) else {
            return WidgetTimerData(isRunning: false, title: nil, startTime: nil)
        }

        let fileURL = containerURL.appendingPathComponent(Self.widgetDataFileName)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return WidgetTimerData(isRunning: false, title: nil, startTime: nil)
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let widgetData = try JSONDecoder().decode(WidgetData.self, from: data)
            return widgetData.timer
        } catch {
            return WidgetTimerData(isRunning: false, title: nil, startTime: nil)
        }
    }
}

// MARK: - Widget View

struct TimerWidgetEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: TimerEntry

    var body: some View {
        if entry.isRunning {
            runningTimerView
        } else {
            idleView
        }
    }

    private var runningTimerView: some View {
        VStack(spacing: 6) {
            // Running indicator
            HStack(spacing: 4) {
                Circle()
                    .fill(.red)
                    .frame(width: 8, height: 8)
                Text("Recording")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.red)
            }

            // Title
            Text(entry.title.isEmpty ? "Timer" : entry.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)
                .foregroundStyle(.secondary)

            // Elapsed time
            Text(DurationFormatter.formatHoursMinutesSeconds(entry.elapsedTime))
                .font(.system(size: widgetFamily == .systemSmall ? 32 : 40, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)

            // Stop indicator
            HStack(spacing: 4) {
                Image(systemName: "stop.fill")
                    .font(.caption)
                Text("Tap to stop")
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var idleView: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock")
                .font(.system(size: 36))
                .foregroundStyle(.blue)

            Text("No timer")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)

            Text("Tap to start")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Widget Definition

struct TimerWidget: Widget {
    let kind: String = "TimerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TimerTimelineProvider()) { entry in
            TimerWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Timer")
        .description("Track your current work session.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Previews

#Preview("Running", as: .systemSmall) {
    TimerWidget()
} timeline: {
    TimerEntry.placeholder
}

#Preview("Idle", as: .systemSmall) {
    TimerWidget()
} timeline: {
    TimerEntry.notRunning
}
