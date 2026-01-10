//
//  FocusSession.swift
//  DevHours
//
//  Tracks individual focus sessions for statistics and streak tracking.
//

import Foundation
import SwiftData

@Model
final class FocusSession {
    var id: UUID
    var startTime: Date
    var endTime: Date?
    var plannedDuration: TimeInterval?  // Target duration (nil = open-ended)
    var overrideCount: Int  // How many times user unlocked blocked apps
    var completedSuccessfully: Bool  // Ended naturally vs cancelled early
    var createdAt: Date

    // Relationship to profile used
    @Relationship(deleteRule: .nullify, inverse: \FocusProfile.sessions)
    var profile: FocusProfile?

    // Relationship to linked time entry (if started with timer)
    var linkedTimeEntryId: UUID?

    init(
        profile: FocusProfile? = nil,
        plannedDuration: TimeInterval? = nil,
        linkedTimeEntryId: UUID? = nil
    ) {
        self.id = UUID()
        self.startTime = Date()
        self.endTime = nil
        self.plannedDuration = plannedDuration
        self.overrideCount = 0
        self.completedSuccessfully = false
        self.createdAt = Date()
        self.profile = profile
        self.linkedTimeEntryId = linkedTimeEntryId
    }

    // MARK: - Computed Properties

    /// Duration of the session
    var duration: TimeInterval {
        let endPoint = endTime ?? Date()
        return endPoint.timeIntervalSince(startTime)
    }

    /// Whether session is still active
    var isActive: Bool {
        endTime == nil
    }

    /// Whether this was a successful session (completed without overrides)
    var wasSuccessful: Bool {
        completedSuccessfully && overrideCount == 0
    }

    /// Progress percentage (0-1) if planned duration is set
    var progressPercentage: Double? {
        guard let planned = plannedDuration, planned > 0 else { return nil }
        return min(1.0, duration / planned)
    }

    /// Whether session qualifies for streak (10+ minutes, successful)
    var qualifiesForStreak: Bool {
        wasSuccessful && duration >= 600  // 10 minutes minimum
    }

    // MARK: - Session Management

    /// End the session
    func end(successful: Bool) {
        self.endTime = Date()
        self.completedSuccessfully = successful
    }

    /// Record an override (user unlocked blocked app)
    func recordOverride() {
        self.overrideCount += 1
    }
}
