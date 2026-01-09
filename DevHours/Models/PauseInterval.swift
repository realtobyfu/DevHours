//
//  PauseInterval.swift
//  DevHours
//
//  Created on 1/8/26.
//

import Foundation
import SwiftData

@Model
final class PauseInterval {
    var id: UUID
    var pausedAt: Date
    var resumedAt: Date?  // nil = currently paused

    @Relationship(inverse: \TimeEntry.pauseIntervals)
    var timeEntry: TimeEntry?

    /// Duration of this pause interval
    var duration: TimeInterval {
        if let resumedAt = resumedAt {
            return resumedAt.timeIntervalSince(pausedAt)
        } else {
            // Currently paused - count until now
            return Date.now.timeIntervalSince(pausedAt)
        }
    }

    init(pausedAt: Date = .now) {
        self.id = UUID()
        self.pausedAt = pausedAt
        self.resumedAt = nil
    }
}
