//
//  SharedDataManager.swift
//  DevHours
//
//  Created on 12/26/24.
//

import Foundation
import SwiftData

@MainActor
final class SharedDataManager {
    static let shared = SharedDataManager()

    static let appGroupIdentifier = "group.com.tobiasfu.DevHours"

    lazy var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TimeEntry.self,
            Client.self,
            Project.self,
            PlannedTask.self,
            RecurrenceRule.self,
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
            running.endTime = .now

            // Auto-complete linked planned task if fully worked
            if let plannedTask = running.sourcePlannedTask, plannedTask.isFullyWorked {
                plannedTask.isCompleted = true
                plannedTask.completedAt = .now
            }

            try? modelContext.save()
        }
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
}
