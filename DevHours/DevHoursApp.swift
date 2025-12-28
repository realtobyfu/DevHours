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
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onAppear {
                    initializeRecurringTasks()
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
}
