//
//  PlannedTask.swift
//  DevHours
//
//  Created on 12/26/24.
//

import Foundation
import SwiftData

@Model
final class PlannedTask {
    var id: UUID
    var title: String
    var plannedDate: Date
    var estimatedDuration: TimeInterval  // in seconds
    var createdAt: Date
    var isCompleted: Bool
    var completedAt: Date?

    // Relationships
    var project: Project?
    var recurrenceRule: RecurrenceRule?

    // For recurring task instances: links back to the parent task
    var parentTaskId: UUID?

    // Link to time entries created when this task is worked on (supports multiple sessions)
    @Relationship(deleteRule: .nullify)
    var linkedTimeEntries: [TimeEntry] = []

    // Tags for categorization (many-to-many)
    @Relationship(deleteRule: .nullify, inverse: \Tag.plannedTasks)
    var tags: [Tag] = []

    // Computed properties
    var isToday: Bool {
        Calendar.current.isDateInToday(plannedDate)
    }

    var isOverdue: Bool {
        !isCompleted && Calendar.current.startOfDay(for: plannedDate) < Calendar.current.startOfDay(for: Date.now)
    }

    /// Total time worked on this task across all sessions
    var workedDuration: TimeInterval {
        linkedTimeEntries.reduce(0) { $0 + $1.duration }
    }

    /// Remaining time until estimated duration is reached
    var remainingDuration: TimeInterval {
        max(0, estimatedDuration - workedDuration)
    }

    /// Whether the task has been worked on for at least the estimated duration
    var isFullyWorked: Bool {
        workedDuration >= estimatedDuration
    }

    /// Check if this is a recurring instance (has a parent)
    var isRecurringInstance: Bool {
        parentTaskId != nil
    }

    /// Check if this is a recurring parent (has a recurrence rule)
    var isRecurringParent: Bool {
        recurrenceRule != nil && parentTaskId == nil
    }

    init(
        title: String,
        plannedDate: Date,
        estimatedDuration: TimeInterval,
        project: Project? = nil,
        recurrenceRule: RecurrenceRule? = nil,
        parentTaskId: UUID? = nil,
        tags: [Tag] = []
    ) {
        self.id = UUID()
        self.title = title
        self.plannedDate = plannedDate
        self.estimatedDuration = estimatedDuration
        self.project = project
        self.recurrenceRule = recurrenceRule
        self.parentTaskId = parentTaskId
        self.isCompleted = false
        self.completedAt = nil
        self.linkedTimeEntries = []
        self.tags = tags
        self.createdAt = Date.now
    }
}
