//
//  TimerIntents.swift
//  DevHours
//
//  Created on 12/26/24.
//

import AppIntents
import WidgetKit

// MARK: - Start Timer Intent

struct StartTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Timer"
    static var description = IntentDescription("Start tracking time")

    static var isDiscoverable: Bool = true

    @Parameter(title: "Title")
    var title: String?

    @MainActor
    func perform() async throws -> some IntentResult {
        SharedDataManager.shared.startTimer(title: title ?? "")
        SharedDataManager.shared.updateWidgetData()
        return .result()
    }
}

// MARK: - Stop Timer Intent

struct StopTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Stop Timer"
    static var description = IntentDescription("Stop the current timer")

    static var isDiscoverable: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        SharedDataManager.shared.stopTimer()
        SharedDataManager.shared.updateWidgetData()
        return .result()
    }
}

// MARK: - Pause Timer Intent

struct PauseTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Pause Timer"
    static var description = IntentDescription("Pause the current timer")

    static var isDiscoverable: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        SharedDataManager.shared.pauseTimer()
        SharedDataManager.shared.updateWidgetData()
        return .result()
    }
}

// MARK: - Resume Timer Intent

struct ResumeTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Resume Timer"
    static var description = IntentDescription("Resume the paused timer")

    static var isDiscoverable: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        SharedDataManager.shared.resumeTimer()
        SharedDataManager.shared.updateWidgetData()
        return .result()
    }
}

// MARK: - Toggle Timer Intent (for widget button)

struct ToggleTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Timer"

    static var isDiscoverable: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult {
        let manager = SharedDataManager.shared
        if manager.currentTimer() != nil {
            manager.stopTimer()
        } else {
            manager.startTimer(title: "")
        }
        manager.updateWidgetData()
        return .result()
    }
}
