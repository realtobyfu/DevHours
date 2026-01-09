//
//  Tag.swift
//  DevHours
//
//  Colored tags for categorizing time entries.
//

import Foundation
import SwiftData

@Model
final class Tag {
    var id: UUID
    var name: String
    var colorHex: String  // Stored as hex string (e.g., "#E53935")
    var createdAt: Date

    // Relationship to time entries (many-to-many)
    var timeEntries: [TimeEntry] = []

    // Relationship to planned tasks (many-to-many)
    var plannedTasks: [PlannedTask] = []

    init(name: String, colorHex: String) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.createdAt = Date()
    }
}
