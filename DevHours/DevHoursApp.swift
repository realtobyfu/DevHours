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
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TimeEntry.self,
            Client.self,
            Project.self,
            PlannedTask.self,
            RecurrenceRule.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onAppear {
                    initializeRecurringTasks()
                }
        }
        .modelContainer(sharedModelContainer)
    }

    private func initializeRecurringTasks() {
        let service = RecurrenceService(modelContext: sharedModelContainer.mainContext)
        service.generateRecurringInstances()
        service.cleanupOldInstances()
    }
}
