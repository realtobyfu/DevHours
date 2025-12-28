//
//  TimerEngine.swift
//  DevHours
//
//  Created on 12/13/24.
//

import Foundation
import SwiftData
import Observation
import ActivityKit

@Observable
final class TimerEngine {
    // MARK: - Published State

    private(set) var runningEntry: TimeEntry?
    private(set) var elapsedTime: TimeInterval = 0

    // MARK: - Private Properties

    private var timer: Timer?
    private let modelContext: ModelContext
    private var currentActivity: Activity<TimerActivityAttributes>?

    // MARK: - Computed Properties

    var isRunning: Bool {
        runningEntry != nil
    }

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        restoreRunningTimer()
    }

    // MARK: - Public Timer Control

    func startTimer(
        title: String = "",
        client: Client? = nil,
        project: Project? = nil,
        sourcePlannedTask: PlannedTask? = nil
    ) {
        guard !isRunning else { return }

        let entry = TimeEntry(
            startTime: Date.now,
            endTime: nil,  // Key: nil = running timer
            title: title,
            client: client,
            project: project
        )

        modelContext.insert(entry)

        // Link to planned task if provided
        if let task = sourcePlannedTask {
            entry.sourcePlannedTask = task
            task.linkedTimeEntries.append(entry)
        }

        try? modelContext.save()

        runningEntry = entry
        startTickTimer()

        // Start Live Activity
        startLiveActivity(title: title, projectName: project?.name, startTime: entry.startTime)

        // Sync widget data
        SharedDataManager.shared.updateWidgetData()
    }

    func stopTimer() {
        guard let entry = runningEntry else { return }

        // Mark as stopped
        entry.endTime = Date.now

        // Auto-complete linked planned task only if fully worked
        if let plannedTask = entry.sourcePlannedTask, plannedTask.isFullyWorked {
            plannedTask.isCompleted = true
            plannedTask.completedAt = Date.now
        }

        try? modelContext.save()

        // End Live Activity
        endLiveActivity()

        // Sync widget data
        SharedDataManager.shared.updateWidgetData()

        // Clean up
        stopTickTimer()
        runningEntry = nil
        elapsedTime = 0
    }

    func updateTitle(_ title: String) {
        guard let entry = runningEntry else { return }
        entry.title = title
        try? modelContext.save()
    }

    // MARK: - Private Helpers

    private func restoreRunningTimer() {
        // Query for any entry with nil endTime (running timer)
        let descriptor = FetchDescriptor<TimeEntry>(
            predicate: #Predicate { $0.endTime == nil },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )

        guard let entries = try? modelContext.fetch(descriptor),
              let entry = entries.first else {
            return
        }

        // Restore the running timer
        runningEntry = entry
        startTickTimer()

        // Restore Live Activity if needed
        restoreLiveActivityIfNeeded()
    }

    private func startTickTimer() {
        // Update UI every second
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateElapsedTime()
        }
        updateElapsedTime() // Initial update
    }

    private func stopTickTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func updateElapsedTime() {
        guard let entry = runningEntry else {
            elapsedTime = 0
            return
        }
        elapsedTime = entry.duration
    }

    // MARK: - Live Activity
    private func startLiveActivity(title: String, projectName: String?, startTime: Date) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("TimerEngine: Live Activities not enabled")
            return
        }

        let attributes = TimerActivityAttributes(
            taskTitle: title,
            projectName: projectName
        )

        let initialState = TimerActivityAttributes.ContentState(
            startTime: startTime,
            isRunning: true
        )

        let content = ActivityContent(
            state: initialState,
            staleDate: Date.distantFuture // Timer style auto-updates
        )

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
            print("TimerEngine: Started Live Activity")
        } catch {
            print("TimerEngine: Failed to start Live Activity - \(error)")
        }
    }

    private func endLiveActivity() {
        guard let activity = currentActivity else {
            // Try to end any orphaned activities
            Task {
                for activity in Activity<TimerActivityAttributes>.activities {
                    await activity.end(nil, dismissalPolicy: .immediate)
                }
            }
            return
        }

        let finalState = TimerActivityAttributes.ContentState(
            startTime: activity.content.state.startTime,
            isRunning: false
        )

        Task {
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .immediate
            )
            print("TimerEngine: Ended Live Activity")
        }

        currentActivity = nil
    }

    /// Restores Live Activity if timer was running when app was killed
    private func restoreLiveActivityIfNeeded() {
        guard let entry = runningEntry else { return }

        // Check if there's already an active Live Activity
        let existingActivities = Activity<TimerActivityAttributes>.activities
        if !existingActivities.isEmpty {
            currentActivity = existingActivities.first
            return
        }

        // No existing activity, start a new one
        startLiveActivity(
            title: entry.title,
            projectName: entry.project?.name,
            startTime: entry.startTime
        )
    }
}
