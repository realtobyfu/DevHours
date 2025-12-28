//
//  AppShortcuts.swift
//  DevHours
//
//  Created on 12/26/24.
//

import AppIntents

struct DevHoursShortcuts: AppShortcutsProvider {
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartTimerIntent(),
            phrases: [
                "Start timer in \(.applicationName)",
                "Start tracking time with \(.applicationName)",
                "Begin timer in \(.applicationName)"
            ],
            shortTitle: LocalizedStringResource("Start Timer"),
            systemImageName: "play.fill"
        )
        AppShortcut(
            intent: StopTimerIntent(),
            phrases: [
                "Stop timer in \(.applicationName)",
                "Stop tracking time with \(.applicationName)",
                "End timer in \(.applicationName)"
            ],
            shortTitle: LocalizedStringResource("Stop Timer"),
            systemImageName: "stop.fill"
        )
    }
}
