//
//  RecurrenceRule.swift
//  DevHours
//
//  Created on 12/26/24.
//

import Foundation
import SwiftData

/// Frequency options for recurring planned tasks
enum RecurrenceFrequency: String, Codable, CaseIterable {
    case daily = "daily"
    case weekdays = "weekdays"  // Mon-Fri
    case weekly = "weekly"
    case monthly = "monthly"

    var displayName: String {
        switch self {
        case .daily: return "Every day"
        case .weekdays: return "Weekdays (Mon-Fri)"
        case .weekly: return "Every week"
        case .monthly: return "Every month"
        }
    }
}

@Model
final class RecurrenceRule {
    var id: UUID
    var frequency: String  // Stored as raw value of RecurrenceFrequency
    var interval: Int      // Every N days/weeks/months (default 1)
    var endDate: Date?     // nil = never ends
    var createdAt: Date

    /// Convenience accessor for frequency enum
    var frequencyType: RecurrenceFrequency? {
        RecurrenceFrequency(rawValue: frequency)
    }

    init(
        frequency: RecurrenceFrequency,
        interval: Int = 1,
        endDate: Date? = nil
    ) {
        self.id = UUID()
        self.frequency = frequency.rawValue
        self.interval = interval
        self.endDate = endDate
        self.createdAt = Date.now
    }
}
