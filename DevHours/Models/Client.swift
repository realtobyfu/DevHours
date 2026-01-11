//
//  Client.swift
//  DevHours
//
//  Created on 12/13/24.
//

import Foundation
import SwiftData

@Model
final class Client {
    var id: UUID = UUID()
    var name: String = ""
    var createdAt: Date = Date.now

    // Relationship: one client has many projects
    @Relationship(deleteRule: .cascade, inverse: \Project.client)
    var projects: [Project]?

    // Relationship: one client has many time entries
    @Relationship(deleteRule: .nullify, inverse: \TimeEntry.client)
    var timeEntries: [TimeEntry]?

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date.now
    }
}
