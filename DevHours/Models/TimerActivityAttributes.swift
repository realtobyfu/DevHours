//
//  TimerActivityAttributes.swift
//  DevHours
//
//  Live Activity attributes for timer tracking.
//

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
        let taskTitle: String
        let projectName: String?
    }
}
