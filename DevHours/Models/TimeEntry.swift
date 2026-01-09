//
//  TimeEntry.swift
//  DevHours
//
//  Created on 12/13/24.
//

import Foundation
import SwiftData

@Model
final class TimeEntry {
    var id: UUID
    var startTime: Date
    var endTime: Date?  // nil = timer still running (critical for persistence!)
    var title: String

    // Relationships (optional for MVP Timer phase, but defined for future)
    var client: Client?
    var project: Project?

    // Link back to the planned task that spawned this entry (if any)
    @Relationship(inverse: \PlannedTask.linkedTimeEntries)
    var sourcePlannedTask: PlannedTask?

    // Tags for categorization (many-to-many)
    @Relationship(deleteRule: .nullify, inverse: \Tag.timeEntries)
    var tags: [Tag] = []

    // Pause intervals for this timer (supports pause/resume functionality)
    @Relationship(deleteRule: .cascade)
    var pauseIntervals: [PauseInterval] = []

    /// Whether the timer is currently paused (running but time frozen)
    var isPaused: Bool {
        guard endTime == nil else { return false }  // Stopped timers aren't paused
        guard let lastPause = pauseIntervals.last else { return false }
        return lastPause.resumedAt == nil
    }

    /// Total duration of all pause intervals
    var totalPausedDuration: TimeInterval {
        pauseIntervals.reduce(0.0) { result, interval in
            result + interval.duration
        }
    }

    // Computed property for duration - excludes paused time
    var duration: TimeInterval {
        let now = Date.now
        let endPoint = endTime ?? now
        let grossDuration = endPoint.timeIntervalSince(startTime)

        // Subtract total paused time for accurate duration
        return max(0, grossDuration - totalPausedDuration)
    }

    // Helper to check if this entry is from today
    var isToday: Bool {
        Calendar.current.isDateInToday(startTime)
    }

    init(
        startTime: Date,
        endTime: Date? = nil,
        title: String = "",
        client: Client? = nil,
        project: Project? = nil
    ) {
        self.id = UUID()
        self.startTime = startTime
        self.endTime = endTime
        self.title = title
        self.client = client
        self.project = project
    }
}
