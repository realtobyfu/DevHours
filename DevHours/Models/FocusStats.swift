//
//  FocusStats.swift
//  DevHours
//
//  Singleton-like model for tracking focus statistics and achievements.
//

import Foundation
import SwiftData

@Model
final class FocusStats {
    var id: UUID = UUID()
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var totalFocusSeconds: Int = 0
    var totalSessionsCompleted: Int = 0
    var totalOverrides: Int = 0  // Lifetime override count
    var lastSuccessfulDate: Date?
    var weeklyGoalMinutes: Int = 300
    var createdAt: Date = Date.now

    // Achievement IDs that have been unlocked
    var unlockedAchievements: [String] = []

    // Weekly session count for free tier limiting
    var weeklySessionCount: Int = 0
    var weekStartDate: Date = FocusStats.startOfWeek()

    init() {
        self.id = UUID()
        self.currentStreak = 0
        self.longestStreak = 0
        self.totalFocusSeconds = 0
        self.totalSessionsCompleted = 0
        self.totalOverrides = 0
        self.lastSuccessfulDate = nil
        self.weeklyGoalMinutes = 300  // 5 hours default
        self.createdAt = Date()
        self.unlockedAchievements = []
        self.weeklySessionCount = 0
        self.weekStartDate = FocusStats.startOfWeek()
    }

    // MARK: - Computed Properties

    var totalFocusMinutes: Int {
        totalFocusSeconds / 60
    }

    var totalFocusHours: Double {
        Double(totalFocusSeconds) / 3600.0
    }

    /// Check if we're still in the same week, reset if not
    var needsWeeklyReset: Bool {
        !Calendar.current.isDate(weekStartDate, equalTo: Date(), toGranularity: .weekOfYear)
    }

    // MARK: - Streak Logic

    /// Update streak after completing a session
    func updateStreak(for session: FocusSession) {
        guard session.qualifiesForStreak else { return }

        let calendar = Calendar.current

        if let lastSuccess = lastSuccessfulDate {
            let daysSince = calendar.dateComponents([.day], from: lastSuccess, to: Date()).day ?? 0

            if daysSince == 1 {
                // Consecutive day
                currentStreak += 1
            } else if daysSince > 1 {
                // Streak broken
                currentStreak = 1
            }
            // daysSince == 0: same day, no change to streak
        } else {
            // First ever successful session
            currentStreak = 1
        }

        longestStreak = max(longestStreak, currentStreak)
        lastSuccessfulDate = Date()
    }

    /// Record a completed session
    func recordSession(_ session: FocusSession) {
        totalFocusSeconds += Int(session.duration)
        totalOverrides += session.overrideCount
        totalSessionsCompleted += 1

        // Update weekly count
        resetWeeklyCountIfNeeded()
        weeklySessionCount += 1

        // Update streak
        updateStreak(for: session)

        // Check for new achievements
        checkAchievements(session: session)
    }

    /// Reset weekly session count if we're in a new week
    func resetWeeklyCountIfNeeded() {
        if needsWeeklyReset {
            weeklySessionCount = 0
            weekStartDate = FocusStats.startOfWeek()
        }
    }

    // MARK: - Achievements

    func checkAchievements(session: FocusSession) {
        var newAchievements: [String] = []

        // First Focus
        if totalSessionsCompleted == 1 && !unlockedAchievements.contains("first_focus") {
            newAchievements.append("first_focus")
        }

        // Week Warrior (7-day streak)
        if currentStreak >= 7 && !unlockedAchievements.contains("week_warrior") {
            newAchievements.append("week_warrior")
        }

        // Habit Forming (14-day streak)
        if currentStreak >= 14 && !unlockedAchievements.contains("habit_forming") {
            newAchievements.append("habit_forming")
        }

        // Monthly Master (30-day streak)
        if currentStreak >= 30 && !unlockedAchievements.contains("monthly_master") {
            newAchievements.append("monthly_master")
        }

        // Hour of Power (60-minute session)
        if session.duration >= 3600 && !unlockedAchievements.contains("hour_of_power") {
            newAchievements.append("hour_of_power")
        }

        // Deep Diver (2-hour session)
        if session.duration >= 7200 && !unlockedAchievements.contains("deep_diver") {
            newAchievements.append("deep_diver")
        }

        // Ironclad (10 sessions with zero overrides)
        let perfectSessions = totalSessionsCompleted - totalOverrides  // Approximation
        if perfectSessions >= 10 && !unlockedAchievements.contains("ironclad") {
            newAchievements.append("ironclad")
        }

        unlockedAchievements.append(contentsOf: newAchievements)
    }

    // MARK: - Helpers

    static func startOfWeek() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        return calendar.date(from: components) ?? Date()
    }
}

// MARK: - Achievement Definitions

struct Achievement: Identifiable {
    let id: String
    let name: String
    let description: String
    let iconName: String

    static let all: [Achievement] = [
        Achievement(
            id: "first_focus",
            name: "First Focus",
            description: "Complete your first focus session",
            iconName: "star.fill"
        ),
        Achievement(
            id: "week_warrior",
            name: "Week Warrior",
            description: "Maintain a 7-day focus streak",
            iconName: "flame.fill"
        ),
        Achievement(
            id: "habit_forming",
            name: "Habit Forming",
            description: "Maintain a 14-day focus streak",
            iconName: "arrow.triangle.2.circlepath"
        ),
        Achievement(
            id: "monthly_master",
            name: "Monthly Master",
            description: "Maintain a 30-day focus streak",
            iconName: "crown.fill"
        ),
        Achievement(
            id: "hour_of_power",
            name: "Hour of Power",
            description: "Complete a 60-minute focus session",
            iconName: "bolt.fill"
        ),
        Achievement(
            id: "deep_diver",
            name: "Deep Diver",
            description: "Complete a 2-hour focus session",
            iconName: "water.waves"
        ),
        Achievement(
            id: "ironclad",
            name: "Ironclad",
            description: "Complete 10 sessions without unlocking blocked apps",
            iconName: "shield.fill"
        ),
    ]

    static func find(by id: String) -> Achievement? {
        all.first { $0.id == id }
    }
}
