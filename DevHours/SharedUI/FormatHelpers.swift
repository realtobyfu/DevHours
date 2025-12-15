//
//  FormatHelpers.swift
//  DevHours
//
//  Created on 12/13/24.
//

import Foundation

enum DurationFormatter {
    /// Formats duration as "2h 35m" for compact display with smart rounding (30s+ rounds up)
    static func formatHoursMinutes(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let remainingSeconds = totalSeconds % 3600
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60

        // Round minutes up if seconds >= 30
        let roundedMinutes = seconds >= 30 ? minutes + 1 : minutes

        // Handle edge case: 59m 30s+ rounds to 1h
        let finalHours: Int
        let finalMinutes: Int

        if roundedMinutes >= 60 {
            finalHours = hours + 1
            finalMinutes = roundedMinutes - 60
        } else {
            finalHours = hours
            finalMinutes = roundedMinutes
        }

        if finalHours > 0 {
            return String(format: "%dh %dm", finalHours, finalMinutes)
        } else if finalMinutes > 0 {
            return String(format: "%dm", finalMinutes)
        } else {
            // Show "0m" for entries under 30 seconds
            return "0m"
        }
    }

    /// Formats duration as "2:35:12" for timer display
    static func formatHoursMinutesSeconds(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    /// Formats duration for accessibility/VoiceOver: "2 hours, 35 minutes, 12 seconds"
    static func formatAccessible(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60

        var components: [String] = []
        if hours > 0 {
            components.append("\(hours) \(hours == 1 ? "hour" : "hours")")
        }
        if minutes > 0 {
            components.append("\(minutes) \(minutes == 1 ? "minute" : "minutes")")
        }
        if seconds > 0 || components.isEmpty {
            components.append("\(seconds) \(seconds == 1 ? "second" : "seconds")")
        }

        return components.joined(separator: ", ")
    }
}
