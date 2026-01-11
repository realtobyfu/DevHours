//
//  TimerActivityAttributes.swift
//  DevHours
//
//  Live Activity attributes for timer tracking.
//

#if !os(macOS)
import ActivityKit
import Foundation

struct TimerActivityAttributes: ActivityAttributes {
    // Static data (set when activity starts, doesn't change)
    let taskTitle: String
    let projectName: String?

    // Dynamic data (can be updated during activity)
    struct ContentState: Codable, Hashable {
        let startTime: Date
        let isRunning: Bool
        let isPaused: Bool
        let elapsedAtPause: TimeInterval?  // Frozen elapsed time when paused
        let taskTitle: String
        let projectName: String?
    }
}
#endif
