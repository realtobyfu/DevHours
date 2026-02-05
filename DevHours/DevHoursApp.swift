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

    @State private var showingOnboarding = !AppOnboardingView.hasCompletedOnboarding

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

                        // Safety-net: if blocking is active but timer is not running,
                        // the timer was stopped without clearing shields (e.g. crash, race condition).
                        if focusBlockingService.isBlocking && timerEngine.runningEntry == nil {
                            focusBlockingService.stopBlocking(successful: true)
                        }
                    }
                }
                #if os(iOS)
                .fullScreenCover(isPresented: $showingOnboarding) {
                    AppOnboardingView {
                        // Onboarding completed
                    }
                }
                #else
                .sheet(isPresented: $showingOnboarding) {
                    AppOnboardingView {
                        // Onboarding completed
                    }
                }
                #endif
        }
        .modelContainer(SharedDataManager.shared.sharedModelContainer)
    }

    private func initializeRecurringTasks() {
        let service = RecurrenceService(modelContext: SharedDataManager.shared.modelContext)
        service.generateRecurringInstances()
        service.cleanupOldInstances()
    }

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

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "devhours" else { return }

        switch url.host {
        case "stop-timer":
            focusBlockingService.stopBlocking(successful: true)
            timerEngine.stopTimer()
        case "pause-timer":
            focusBlockingService.pauseBlocking()
            timerEngine.pauseTimer()
        case "resume-timer":
            focusBlockingService.resumeBlocking()
            timerEngine.resumeTimer()
        case "end-focus":
            // End the focus session directly
            focusBlockingService.checkForEndSessionRequest()
        default:
            break
        }
        SharedDataManager.shared.updateWidgetData()
    }
}
