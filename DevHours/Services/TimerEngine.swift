//
//  TimerEngine.swift
//  DevHours
//
//  Created on 12/13/24.
//

import Foundation
import SwiftData
import Observation

@Observable
final class TimerEngine {
    // MARK: - Published State

    private(set) var runningEntry: TimeEntry?
    private(set) var elapsedTime: TimeInterval = 0

    // MARK: - Private Properties

    private var timer: Timer?
    private let modelContext: ModelContext

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
}
