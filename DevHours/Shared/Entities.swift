//
//  Entities.swift
//  DevHours
//
//  Created by Tobias on 12/27/25.
//
import Foundation

// MARK: - Shared Data Types (JSON-based, no SwiftData)

struct WidgetTaskData: Codable, Identifiable {
    let id: UUID
    let title: String
    let estimatedDuration: TimeInterval
    let isCompleted: Bool
}

struct WidgetTimerData: Codable {
    let isRunning: Bool
    let isPaused: Bool
    let title: String?
    let startTime: Date?
    let elapsedAtPause: TimeInterval?  // Frozen elapsed time when paused
}

struct WidgetData: Codable {
    let tasks: [WidgetTaskData]
    let timer: WidgetTimerData
    let lastUpdated: Date
}
