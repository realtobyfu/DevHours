//
//  DevHoursWidgets.swift
//  DevHoursWidgets
//
//  Widget displaying today's planned tasks.
//

import WidgetKit
import SwiftUI


// MARK: - Timeline Entry

struct TasksEntry: TimelineEntry {
    let date: Date
    let tasks: [WidgetTaskData]
    let relevance: TimelineEntryRelevance?

    static var placeholder: TasksEntry {
        TasksEntry(date: .now, tasks: [
            WidgetTaskData(id: UUID(), title: "Design review", estimatedDuration: 3600, isCompleted: false),
            WidgetTaskData(id: UUID(), title: "Code cleanup", estimatedDuration: 1800, isCompleted: false),
            WidgetTaskData(id: UUID(), title: "Write docs", estimatedDuration: 2700, isCompleted: false)
        ], relevance: TimelineEntryRelevance(score: 1.0))
    }

    static var empty: TasksEntry {
        TasksEntry(date: .now, tasks: [], relevance: TimelineEntryRelevance(score: 0.1))
    }
}

// MARK: - Timeline Provider

struct TasksTimelineProvider: TimelineProvider {
    private static let appGroupIdentifier = "group.com.tobiasfu.DevHours"
    private static let widgetDataFileName = "widget-tasks.json"

    func placeholder(in context: Context) -> TasksEntry {
        TasksEntry.placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (TasksEntry) -> Void) {
        if context.isPreview {
            completion(TasksEntry.placeholder)
        } else {
            let tasks = loadTasks()
            let relevance = calculateRelevance(for: tasks)
            completion(TasksEntry(date: .now, tasks: tasks, relevance: relevance))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TasksEntry>) -> Void) {
        let tasks = loadTasks()
        let relevance = calculateRelevance(for: tasks)
        let entry = TasksEntry(date: .now, tasks: tasks, relevance: relevance)

        // Refresh every 15 minutes or at midnight
        let midnight = Calendar.current.startOfDay(for: Date().addingTimeInterval(86400))
        let fifteenMinutes = Date().addingTimeInterval(15 * 60)
        let nextRefresh = min(midnight, fifteenMinutes)

        let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
        completion(timeline)
    }

    /// Calculate Smart Stack relevance based on task state
    private func calculateRelevance(for tasks: [WidgetTaskData]) -> TimelineEntryRelevance {
        if tasks.isEmpty {
            // No tasks - low relevance
            return TimelineEntryRelevance(score: 0.1)
        }

        let hasIncompleteTasks = tasks.contains { !$0.isCompleted }
        if hasIncompleteTasks {
            // Has work to do - high relevance
            return TimelineEntryRelevance(score: 1.0)
        } else {
            // All done - moderate relevance
            return TimelineEntryRelevance(score: 0.3)
        }
    }

    private func loadTasks() -> [WidgetTaskData] {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Self.appGroupIdentifier
        ) else {
            print("Widget: Failed to get app group container")
            return []
        }

        let fileURL = containerURL.appendingPathComponent(Self.widgetDataFileName)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("Widget: No widget data file found")
            return []
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let widgetData = try JSONDecoder().decode(WidgetData.self, from: data)
            return widgetData.tasks
        } catch {
            print("Widget: Failed to load tasks - \(error)")
            return []
        }
    }
}

// MARK: - Widget Views

struct TodayTasksWidgetEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: TasksEntry

    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            MediumWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget

struct SmallWidgetView: View {
    let entry: TasksEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checklist")
                    .font(.headline)
                    .foregroundStyle(.blue)
                Text("Today")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

            if entry.tasks.isEmpty {
                Spacer()
                Text("No tasks")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                ForEach(entry.tasks.prefix(2)) { task in
                    TaskRowCompact(task: task)
                }

                Spacer(minLength: 0)

                if entry.tasks.count > 2 {
                    Text("+\(entry.tasks.count - 2) more")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let entry: TasksEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "checklist")
                    .font(.headline)
                    .foregroundStyle(.blue)
                Text("Today's Tasks")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                if !entry.tasks.isEmpty {
                    Text("\(entry.tasks.count)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if entry.tasks.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Image(systemName: "checkmark.circle")
                            .font(.title2)
                            .foregroundStyle(.green)
                        Text("All done!")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                Spacer()
            } else {
                ForEach(entry.tasks.prefix(3)) { task in
                    TaskRow(task: task)
                }

                Spacer(minLength: 0)

                if entry.tasks.count > 3 {
                    Text("+\(entry.tasks.count - 3) more tasks")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Task Row Components

struct TaskRow: View {
    let task: WidgetTaskData

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.body)
                .foregroundStyle(task.isCompleted ? .green : .secondary)

            Text(task.title.isEmpty ? "Untitled" : task.title)
                .font(.subheadline)
                .lineLimit(1)
                .strikethrough(task.isCompleted)
                .foregroundStyle(task.isCompleted ? .secondary : .primary)

            Spacer(minLength: 4)

            HStack(spacing: 3) {
                Image(systemName: "clock")
                    .font(.caption2)
                Text(DurationFormatter.formatHoursMinutes(task.estimatedDuration))
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
        }
    }
}

struct TaskRowCompact: View {
    let task: WidgetTaskData

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.caption)
                .foregroundStyle(task.isCompleted ? .green : .secondary)

            Text(task.title.isEmpty ? "Untitled" : task.title)
                .font(.caption)
                .lineLimit(1)
                .strikethrough(task.isCompleted)
                .foregroundStyle(task.isCompleted ? .secondary : .primary)

            Spacer(minLength: 2)

            Text(DurationFormatter.formatHoursMinutes(task.estimatedDuration))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Widget Definition

struct TodayTasksWidget: Widget {
    let kind: String = "TodayTasksWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TasksTimelineProvider()) { entry in
            TodayTasksWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Today's Tasks")
        .description("See your planned tasks for today.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    TodayTasksWidget()
} timeline: {
    TasksEntry.placeholder
}

#Preview("Medium", as: .systemMedium) {
    TodayTasksWidget()
} timeline: {
    TasksEntry.placeholder
}

#Preview("Empty", as: .systemMedium) {
    TodayTasksWidget()
} timeline: {
    TasksEntry.empty
}
