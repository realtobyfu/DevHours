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

    // Computed property for duration - always accurate
    var duration: TimeInterval {
        if let endTime = endTime {
            // Stopped timer - fixed duration
            return endTime.timeIntervalSince(startTime)
        } else {
            // Running timer - calculate from now
            return Date.now.timeIntervalSince(startTime)
        }
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
