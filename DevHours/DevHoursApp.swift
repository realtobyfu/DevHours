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
    @Environment(\.scenePhase) private var scenePhase

    @State private var timerEngine = TimerEngine(
        modelContext: SharedDataManager.shared.modelContext
    )

    @State private var focusBlockingService = FocusBlockingService(
        modelContext: SharedDataManager.shared.modelContext
    )

    @State private var premiumManager = PremiumManager()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(timerEngine)
                .environment(focusBlockingService)
                .environment(premiumManager)
                .onAppear {
                    initializeRecurringTasks()
                    initializeFocusMode()
                    SharedDataManager.shared.updateWidgetData()
                }
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        // Check if shield requested to end focus session
                        focusBlockingService.checkForEndSessionRequest()
                    }
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
    private func initializeFocusMode() {
        // Configure premium manager with focus service
        premiumManager.configure(with: focusBlockingService)

        // Create default profiles if needed (only after authorization)
        focusBlockingService.checkAuthorizationStatus()
        if focusBlockingService.isAuthorized {
            focusBlockingService.ensureDefaultProfiles()
        }

        // Check subscription status
        Task {
            await premiumManager.checkSubscriptionStatus()
        }
    }

    @MainActor
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "devhours" else { return }

        switch url.host {
        case "stop-timer":
            timerEngine.stopTimer()
        case "pause-timer":
            timerEngine.pauseTimer()
        case "resume-timer":
            timerEngine.resumeTimer()
        default:
            break
        }
        SharedDataManager.shared.updateWidgetData()
    }
}
