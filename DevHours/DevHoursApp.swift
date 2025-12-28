//
//  DevHoursApp.swift
//  DevHours
//
//  Created by Tobias Fu on 12/13/25.
//

import SwiftUI
import SwiftData

@main
struct DevHoursApp: App {
    @State private var timerEngine: TimerEngine?

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onAppear {
                    initializeRecurringTasks()
                    SharedDataManager.shared.updateWidgetData()
                    // Initialize timer engine for URL handling
                    if timerEngine == nil {
                        timerEngine = TimerEngine(modelContext: SharedDataManager.shared.modelContext)
                    }
                }
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
        .modelContainer(SharedDataManager.shared.sharedModelContainer)
    }

    @MainActor
    private func initializeRecurringTasks() {
        let service = RecurrenceService(modelContext: SharedDataManager.shared.modelContext)
        service.generateRecurringInstances()
        service.cleanupOldInstances()
    }

    @MainActor
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "devhours" else { return }

        switch url.host {
        case "stop-timer":
            timerEngine?.stopTimer()
            SharedDataManager.shared.updateWidgetData()
        default:
            break
        }
    }
}
