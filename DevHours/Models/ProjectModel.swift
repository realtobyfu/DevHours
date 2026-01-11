//
//  ProjectModel.swift
//  DevHours
//
//  Created on 12/13/24.
//

import Foundation
import SwiftData

@Model
final class Project {
    var id: UUID = UUID()
    var name: String = ""
    var createdAt: Date = Date.now
    var isBillable: Bool = true

    // Relationship: many projects belong to one client
    var client: Client?

    // Relationship: one project has many time entries
    @Relationship(deleteRule: .nullify, inverse: \TimeEntry.project)
    var timeEntries: [TimeEntry]?

    // Relationship: one project has many planned tasks
    @Relationship(deleteRule: .nullify, inverse: \PlannedTask.project)
    var plannedTasks: [PlannedTask]?

    init(name: String, client: Client? = nil, isBillable: Bool = true) {
        self.id = UUID()
        self.name = name
        self.client = client
        self.isBillable = isBillable
        self.createdAt = Date.now
    }
}
