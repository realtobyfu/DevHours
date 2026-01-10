//
//  SharedDataManager.swift
//  DevHours
//
//  Created on 12/26/24.
//

import Foundation
import SwiftData
import WidgetKit

@MainActor
final class SharedDataManager {
    static let shared = SharedDataManager()

    static let appGroupIdentifier = "group.com.tobiasfu.DevHours"
    private static let widgetDataFileName = "widget-tasks.json"

    lazy var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TimeEntry.self,
            Client.self,
            Project.self,
            PlannedTask.self,
            RecurrenceRule.self,
            Tag.self,
            PauseInterval.self,
            // Focus Mode models
            FocusProfile.self,
            FocusSession.self,
            FocusStats.self,
        ])
        let config = ModelConfiguration(
            schema: schema,
            groupContainer: .identifier(Self.appGroupIdentifier)
        )
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create shared ModelContainer: \(error)")
        }
    }()

    var modelContext: ModelContext {
        sharedModelContainer.mainContext
    }

    // MARK: - Timer Operations

    func startTimer(title: String, projectId: UUID? = nil) {
        let entry = TimeEntry(startTime: .now, title: title)
        if let projectId {
            let descriptor = FetchDescriptor<Project>(predicate: #Predicate { $0.id == projectId })
            entry.project = try? modelContext.fetch(descriptor).first
        }
        modelContext.insert(entry)
        try? modelContext.save()
    }

    func stopTimer() {
        let descriptor = FetchDescriptor<TimeEntry>(predicate: #Predicate { $0.endTime == nil })
        if let running = try? modelContext.fetch(descriptor).first {
            // If paused, close the open pause interval first
            if let currentPause = running.pauseIntervals.last,
               currentPause.resumedAt == nil {
                currentPause.resumedAt = .now
            }

            running.endTime = .now

            // Auto-complete linked planned task if fully worked
            if let plannedTask = running.sourcePlannedTask, plannedTask.isFullyWorked {
                plannedTask.isCompleted = true
                plannedTask.completedAt = .now
            }

            try? modelContext.save()
        }
    }

    func pauseTimer() {
        let descriptor = FetchDescriptor<TimeEntry>(predicate: #Predicate { $0.endTime == nil })
        guard let running = try? modelContext.fetch(descriptor).first,
              !running.isPaused else { return }

        let pauseInterval = PauseInterval(pausedAt: .now)
        pauseInterval.timeEntry = running
        running.pauseIntervals.append(pauseInterval)
        modelContext.insert(pauseInterval)
        try? modelContext.save()
    }

    func resumeTimer() {
        let descriptor = FetchDescriptor<TimeEntry>(predicate: #Predicate { $0.endTime == nil })
        guard let running = try? modelContext.fetch(descriptor).first,
              let currentPause = running.pauseIntervals.last,
              currentPause.resumedAt == nil else { return }

        currentPause.resumedAt = .now
        try? modelContext.save()
    }

    func currentTimer() -> TimeEntry? {
        let descriptor = FetchDescriptor<TimeEntry>(predicate: #Predicate { $0.endTime == nil })
        return try? modelContext.fetch(descriptor).first
    }

    func todayPlannedTasks() -> [PlannedTask] {
        let descriptor = FetchDescriptor<PlannedTask>(sortBy: [SortDescriptor(\.estimatedDuration, order: .reverse)])
        let all = (try? modelContext.fetch(descriptor)) ?? []
        return all.filter { $0.isToday && !$0.isCompleted }
    }

    func todayTotalDuration() -> TimeInterval {
        let descriptor = FetchDescriptor<TimeEntry>(sortBy: [SortDescriptor(\.startTime)])
        let all = (try? modelContext.fetch(descriptor)) ?? []
        return all.filter { $0.isToday }.reduce(0) { $0 + $1.duration }
    }

    // MARK: - Widget Data Sync
    /// Updates the widget data file with today's planned tasks and timer state
    func updateWidgetData() {
        let tasks = todayPlannedTasks()
        let runningTimer = currentTimer()

        let widgetTasks = tasks.map { task in
            WidgetTaskData(
                id: task.id,
                title: task.title,
                estimatedDuration: task.estimatedDuration,
                isCompleted: task.isCompleted
            )
        }

        let isPaused = runningTimer?.isPaused ?? false
        let widgetTimer = WidgetTimerData(
            isRunning: runningTimer != nil && !isPaused,
            isPaused: isPaused,
            title: runningTimer?.title,
            startTime: runningTimer?.startTime,
            elapsedAtPause: isPaused ? runningTimer?.duration : nil
        )

        let widgetData = WidgetData(
            tasks: widgetTasks,
            timer: widgetTimer,
            lastUpdated: Date()
        )

        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Self.appGroupIdentifier
        ) else {
            print("SharedDataManager: Failed to get app group container")
            return
        }

        let fileURL = containerURL.appendingPathComponent(Self.widgetDataFileName)

        do {
            let data = try JSONEncoder().encode(widgetData)
            try data.write(to: fileURL)
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("SharedDataManager: Failed to write widget data - \(error)")
        }
    }
}
