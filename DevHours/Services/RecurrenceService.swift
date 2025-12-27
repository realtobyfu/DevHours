//
//  RecurrenceService.swift
//  DevHours
//
//  Created on 12/26/24.
//

import Foundation
import SwiftData

final class RecurrenceService {
    private let modelContext: ModelContext
    private let calendar = Calendar.current

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Generate future instances of recurring tasks
    /// Call this on app launch
    func generateRecurringInstances(daysAhead: Int = 30) {
        // Fetch all recurring parent tasks (have recurrence rule, no parent)
        let descriptor = FetchDescriptor<PlannedTask>(
            predicate: #Predicate { task in
                task.recurrenceRule != nil && task.parentTaskId == nil
            }
        )

        guard let parentTasks = try? modelContext.fetch(descriptor) else { return }

        for parentTask in parentTasks {
            generateInstances(for: parentTask, daysAhead: daysAhead)
        }

        try? modelContext.save()
    }

    /// Clean up old completed instances (older than 30 days)
    func cleanupOldInstances() {
        let cutoffDate = calendar.date(byAdding: .day, value: -30, to: Date.now)!

        // Fetch old completed instances
        let descriptor = FetchDescriptor<PlannedTask>(
            predicate: #Predicate { task in
                task.isCompleted && task.parentTaskId != nil
            }
        )

        guard let instances = try? modelContext.fetch(descriptor) else { return }

        // Filter for old ones (can't do date comparison in predicate with calculated date)
        let oldInstances = instances.filter { $0.plannedDate < cutoffDate }

        for instance in oldInstances {
            modelContext.delete(instance)
        }

        try? modelContext.save()
    }

    // MARK: - Private Helpers

    private func generateInstances(for parentTask: PlannedTask, daysAhead: Int) {
        guard let rule = parentTask.recurrenceRule else { return }

        let endDate = calendar.date(byAdding: .day, value: daysAhead, to: Date.now)!
        let ruleEndDate = rule.endDate ?? endDate
        let actualEndDate = min(endDate, ruleEndDate)

        // Get existing instance dates for this parent
        let existingDates = getExistingInstanceDates(parentId: parentTask.id)

        // Generate dates based on frequency
        var currentDate = parentTask.plannedDate

        // Start from today if the parent date is in the past
        let today = calendar.startOfDay(for: Date.now)
        if currentDate < today {
            currentDate = nextOccurrence(from: today, rule: rule, originalDate: parentTask.plannedDate)
        }

        while currentDate <= actualEndDate {
            let dayStart = calendar.startOfDay(for: currentDate)

            // Only create if instance doesn't exist for this day
            if !existingDates.contains(dayStart) {
                createInstance(from: parentTask, for: currentDate)
            }

            // Get next date
            guard let nextDate = nextDate(from: currentDate, rule: rule) else { break }
            currentDate = nextDate
        }
    }

    private func getExistingInstanceDates(parentId: UUID) -> Set<Date> {
        let descriptor = FetchDescriptor<PlannedTask>(
            predicate: #Predicate { task in
                task.parentTaskId != nil
            }
        )

        guard let instances = try? modelContext.fetch(descriptor) else {
            return []
        }

        // Filter for this parent's instances
        let filteredInstances = instances.filter { $0.parentTaskId == parentId }

        return Set(filteredInstances.map { calendar.startOfDay(for: $0.plannedDate) })
    }

    private func nextDate(from date: Date, rule: RecurrenceRule) -> Date? {
        guard let frequency = RecurrenceFrequency(rawValue: rule.frequency) else {
            return nil
        }

        switch frequency {
        case .daily:
            return calendar.date(byAdding: .day, value: rule.interval, to: date)

        case .weekdays:
            var next = calendar.date(byAdding: .day, value: 1, to: date)!
            // Skip weekends
            while calendar.isDateInWeekend(next) {
                next = calendar.date(byAdding: .day, value: 1, to: next)!
            }
            return next

        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: rule.interval, to: date)

        case .monthly:
            return calendar.date(byAdding: .month, value: rule.interval, to: date)
        }
    }

    private func nextOccurrence(from targetDate: Date, rule: RecurrenceRule, originalDate: Date) -> Date {
        guard let frequency = RecurrenceFrequency(rawValue: rule.frequency) else {
            return targetDate
        }

        var candidate = originalDate

        switch frequency {
        case .daily:
            // Find the next daily occurrence on or after targetDate
            let daysDiff = calendar.dateComponents([.day], from: originalDate, to: targetDate).day ?? 0
            let intervalsNeeded = (daysDiff / rule.interval) + (daysDiff % rule.interval > 0 ? 1 : 0)
            candidate = calendar.date(byAdding: .day, value: intervalsNeeded * rule.interval, to: originalDate)!

        case .weekdays:
            candidate = targetDate
            while calendar.isDateInWeekend(candidate) {
                candidate = calendar.date(byAdding: .day, value: 1, to: candidate)!
            }

        case .weekly:
            let weeksDiff = calendar.dateComponents([.weekOfYear], from: originalDate, to: targetDate).weekOfYear ?? 0
            let intervalsNeeded = (weeksDiff / rule.interval) + (weeksDiff % rule.interval > 0 ? 1 : 0)
            candidate = calendar.date(byAdding: .weekOfYear, value: intervalsNeeded * rule.interval, to: originalDate)!

        case .monthly:
            let monthsDiff = calendar.dateComponents([.month], from: originalDate, to: targetDate).month ?? 0
            let intervalsNeeded = (monthsDiff / rule.interval) + (monthsDiff % rule.interval > 0 ? 1 : 0)
            candidate = calendar.date(byAdding: .month, value: intervalsNeeded * rule.interval, to: originalDate)!
        }

        // Make sure we're on or after target date
        if candidate < targetDate {
            return nextDate(from: candidate, rule: rule) ?? candidate
        }

        return candidate
    }

    private func createInstance(from parent: PlannedTask, for date: Date) {
        let instance = PlannedTask(
            title: parent.title,
            plannedDate: date,
            estimatedDuration: parent.estimatedDuration,
            project: parent.project,
            parentTaskId: parent.id
        )
        modelContext.insert(instance)
    }
}
