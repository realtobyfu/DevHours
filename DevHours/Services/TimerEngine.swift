//
//  TimerEngine.swift
//  DevHours
//
//  Created on 12/13/24.
//

import Foundation
import SwiftData
import Observation
#if !os(macOS)
import ActivityKit
#endif

@Observable
final class TimerEngine {
    // MARK: - Published State

    private(set) var runningEntry: TimeEntry?
    private(set) var elapsedTime: TimeInterval = 0
    private(set) var isPaused: Bool = false

    // MARK: - Private Properties

    private var timer: Timer?
    private let modelContext: ModelContext
    #if !os(macOS)
    private var currentActivity: Activity<TimerActivityAttributes>?
    #endif

    // MARK: - Computed Properties

    /// True if timer is running (not paused)
    var isRunning: Bool {
        runningEntry != nil && !isPaused
    }

    /// True if there's an active timer (running or paused)
    var hasActiveTimer: Bool {
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

        // If paused, close the open pause interval first
        if let currentPause = entry.pauseIntervals.last,
           currentPause.resumedAt == nil {
            currentPause.resumedAt = Date.now
        }

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
        isPaused = false
    }

    func pauseTimer() {
        guard let entry = runningEntry, !isPaused else { return }

        let pauseInterval = PauseInterval(pausedAt: Date.now)
        pauseInterval.timeEntry = entry
        entry.pauseIntervals.append(pauseInterval)
        modelContext.insert(pauseInterval)

        try? modelContext.save()

        isPaused = true
        stopTickTimer()

        // Update Live Activity to show paused state
        updateLiveActivityPaused()

        // Sync widget data
        SharedDataManager.shared.updateWidgetData()
    }

    func resumeTimer() {
        guard let entry = runningEntry,
              let currentPause = entry.pauseIntervals.last,
              currentPause.resumedAt == nil else { return }

        currentPause.resumedAt = Date.now
        try? modelContext.save()

        isPaused = false
        startTickTimer()

        // Update Live Activity to show running state
        updateLiveActivityResumed()

        // Sync widget data
        SharedDataManager.shared.updateWidgetData()
    }

    func updateTitle(_ title: String) {
        guard let entry = runningEntry else { return }
        entry.title = title
        try? modelContext.save()
        updateLiveActivity(title: title, projectName: entry.project?.name)
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
        isPaused = entry.isPaused

        // Only start tick timer if not paused
        if !isPaused {
            startTickTimer()
        } else {
            // Update elapsed time once to show frozen value
            updateElapsedTime()
        }

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
    #if !os(macOS)
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
            isRunning: true,
            isPaused: false,
            elapsedAtPause: nil,
            taskTitle: title,
            projectName: projectName
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
            isRunning: false,
            isPaused: false,
            elapsedAtPause: nil,
            taskTitle: activity.content.state.taskTitle,
            projectName: activity.content.state.projectName
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

    private func updateLiveActivity(title: String, projectName: String?) {
        guard let activity = currentActivity else { return }

        let updatedState = TimerActivityAttributes.ContentState(
            startTime: activity.content.state.startTime,
            isRunning: true,
            isPaused: false,
            elapsedAtPause: nil,
            taskTitle: title,
            projectName: projectName
        )

        Task {
            await activity.update(ActivityContent(state: updatedState, staleDate: Date.distantFuture))
        }
    }

    private func updateLiveActivityPaused() {
        guard let activity = currentActivity,
              let entry = runningEntry else { return }

        let pausedState = TimerActivityAttributes.ContentState(
            startTime: activity.content.state.startTime,
            isRunning: false,
            isPaused: true,
            elapsedAtPause: entry.duration,  // Freeze at current duration
            taskTitle: activity.content.state.taskTitle,
            projectName: activity.content.state.projectName
        )

        Task {
            await activity.update(ActivityContent(state: pausedState, staleDate: nil))
        }
    }

    private func updateLiveActivityResumed() {
        guard let activity = currentActivity,
              let entry = runningEntry else { return }

        // Calculate effective start time to make timer display correctly
        // The timer displays time since startTime, so we adjust it to account for already elapsed time
        let effectiveStartTime = Date.now.addingTimeInterval(-entry.duration)

        let runningState = TimerActivityAttributes.ContentState(
            startTime: effectiveStartTime,
            isRunning: true,
            isPaused: false,
            elapsedAtPause: nil,
            taskTitle: activity.content.state.taskTitle,
            projectName: activity.content.state.projectName
        )

        Task {
            await activity.update(ActivityContent(state: runningState, staleDate: Date.distantFuture))
        }
    }

    /// Restores Live Activity if timer was running when app was killed
    private func restoreLiveActivityIfNeeded() {
        guard let entry = runningEntry else { return }

        // Check if there's already an active Live Activity
        let existingActivities = Activity<TimerActivityAttributes>.activities
        if !existingActivities.isEmpty {
            currentActivity = existingActivities.first

            // If paused, update the Live Activity to show paused state
            if isPaused {
                updateLiveActivityPaused()
            }
            return
        }

        // No existing activity, start a new one
        if isPaused {
            // Start in paused state
            startLiveActivityPaused(entry: entry)
        } else {
            startLiveActivity(
                title: entry.title,
                projectName: entry.project?.name,
                startTime: entry.startTime
            )
        }
    }

    private func startLiveActivityPaused(entry: TimeEntry) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = TimerActivityAttributes(
            taskTitle: entry.title,
            projectName: entry.project?.name
        )

        let pausedState = TimerActivityAttributes.ContentState(
            startTime: entry.startTime,
            isRunning: false,
            isPaused: true,
            elapsedAtPause: entry.duration,
            taskTitle: entry.title,
            projectName: entry.project?.name
        )

        let content = ActivityContent(state: pausedState, staleDate: nil)

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
        } catch {
            print("TimerEngine: Failed to start paused Live Activity - \(error)")
        }
    }
    #else
    private func startLiveActivity(title: String, projectName: String?, startTime: Date) {}
    private func endLiveActivity() {}
    private func updateLiveActivity(title: String, projectName: String?) {}
    private func updateLiveActivityPaused() {}
    private func updateLiveActivityResumed() {}
    private func restoreLiveActivityIfNeeded() {}
    private func startLiveActivityPaused(entry: TimeEntry) {}
    #endif
}
