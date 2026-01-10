//
//  TodayView.swift
//  DevHours
//
//  Created on 12/13/24.
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(TimerEngine.self) private var timerEngine
    @Environment(FocusBlockingService.self) private var focusService
    @Environment(PremiumManager.self) private var premiumManager

    // Query all entries, then filter for today in Swift code
    @Query(sort: \TimeEntry.startTime, order: .reverse)
    private var allEntries: [TimeEntry]

    // Query all planned tasks, then filter for today
    @Query(sort: \PlannedTask.estimatedDuration, order: .reverse)
    private var allPlannedTasks: [PlannedTask]

    @State private var titleInput = ""
    @State private var titleUpdateTask: Task<Void, Never>?

    // Focus Mode state
    @State private var focusModeEnabled = false
    @State private var selectedFocusProfile: FocusProfile?
    @State private var showingFocusSuggestion = false

    // Filter for today's entries (Calendar methods not supported in @Query predicates)
    private var todayEntries: [TimeEntry] {
        allEntries.filter { Calendar.current.isDateInToday($0.startTime) }
    }

    // Filter for today's incomplete planned tasks
    private var todayPlannedTasks: [PlannedTask] {
        allPlannedTasks.filter { $0.isToday && !$0.isCompleted }
    }

    // Total duration for summary header
    private var totalDurationToday: TimeInterval {
        todayEntries.reduce(0) { $0 + $1.duration }
    }

    // Check if currently running timer is from a planned task
    private var isRunningPlannedTask: Bool {
        timerEngine.runningEntry?.sourcePlannedTask != nil
    }

    // Get the currently running planned task (if any)
    private var runningPlannedTask: PlannedTask? {
        timerEngine.runningEntry?.sourcePlannedTask
    }

    // Check if there's any active timer (running or paused)
    private var hasActiveTimer: Bool {
        timerEngine.hasActiveTimer
    }

    var body: some View {
        NavigationStack {
            List {
                // Daily Summary Section
                if !todayEntries.isEmpty {
                    DailySummaryHeader(
                        totalDuration: totalDurationToday,
                        entryCount: todayEntries.count
                    )
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                // Active Timer Section (when working on a planned task)
                if let runningTask = runningPlannedTask {
                    Section {
                        TimerCardContainer(
                            task: runningTask,
                            isRunning: timerEngine.isRunning,
                            isPaused: timerEngine.isPaused,
                            elapsedTime: timerEngine.elapsedTime,
                            onStart: startPlannedTask,
                            onStop: stopTimer,
                            onPause: pauseTimer,
                            onResume: resumeTimer,
                            tintColor: .blue
                        )
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    } header: {
                        Text("Working On")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                            .textCase(nil)
                    }
                }

                // Ad-hoc Timer Control Section (hidden when working on a planned task)
                if !isRunningPlannedTask {
                    EnhancedTimerCard(
                        isRunning: timerEngine.isRunning,
                        isPaused: timerEngine.isPaused,
                        isLocked: false,
                        titleInput: $titleInput,
                        elapsedTime: timerEngine.elapsedTime,
                        onStart: startTimer,
                        onStop: stopTimer,
                        onPause: pauseTimer,
                        onResume: resumeTimer,
                        focusModeEnabled: $focusModeEnabled,
                        selectedFocusProfile: $selectedFocusProfile
                    )
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                // Planned Tasks Section (hidden when any timer is active - running or paused)
                if !todayPlannedTasks.isEmpty && !hasActiveTimer {
                    Section {
                        // First row: show up to two compact cards side by side.
                        HStack(spacing: 12) {
                            ForEach(Array(todayPlannedTasks.prefix(2).enumerated()), id: \.element.id) { index, task in
                                TimerCardContainer(
                                    task: task,
                                    isRunning: false,
                                    isPaused: false,
                                    elapsedTime: 0,
                                    onStart: startPlannedTask,
                                    onStop: stopTimer,
                                    onPause: pauseTimer,
                                    onResume: resumeTimer,
                                    tintColor: TimerCardContainer.cardTints[index % TimerCardContainer.cardTints.count],
                                    isCompact: true
                                )
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)

                        // Remaining tasks (if any): full-width stack.
                        ForEach(Array(todayPlannedTasks.dropFirst(2).enumerated()), id: \.element.id) { offset, task in
                            let index = offset + 2
                            TimerCardContainer(
                                task: task,
                                isRunning: false,
                                isPaused: false,
                                elapsedTime: 0,
                                onStart: startPlannedTask,
                                onStop: stopTimer,
                                onPause: pauseTimer,
                                onResume: resumeTimer,
                                tintColor: TimerCardContainer.cardTints[index % TimerCardContainer.cardTints.count]
                            )
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                    } header: {
                        Text("Planned for Today")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                            .textCase(nil)
                    }
                }


                // Today's Entries Section
                if !todayEntries.isEmpty {
                    Section {
                        ForEach(todayEntries) { entry in
                            TodayEntryRow(entry: entry)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteEntry(entry)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        deleteEntry(entry)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    } header: {
                        Text("Today's Entries")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                            .textCase(nil)
                    }
                } else if !hasActiveTimer {
                    EmptyTodayState()
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.secondarySystemBackground)
            .navigationTitle("Today")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
        }
        .onChange(of: titleInput) { _, newValue in
            titleUpdateTask?.cancel()
            guard timerEngine.isRunning else { return }
            titleUpdateTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 350_000_000)
                guard !Task.isCancelled else { return }
                timerEngine.updateTitle(newValue)
            }
        }
        .onAppear {
            titleInput = timerEngine.runningEntry?.title ?? ""
        }
        .onChange(of: timerEngine.runningEntry?.id) { _, _ in
            titleInput = timerEngine.runningEntry?.title ?? ""
        }
    }

    // MARK: - Actions
    private func startTimer() {
        timerEngine.startTimer(title: titleInput)

        // Start focus blocking if enabled
        if focusModeEnabled, let profile = selectedFocusProfile {
            if let entryId = timerEngine.runningEntry?.id {
                focusService.startBlocking(profile: profile, linkedTimeEntryId: entryId)
            }
        }

        // Keep titleInput so user can continue editing while timer runs
    }

    private func stopTimer() {
        // Stop focus blocking if active
        if focusService.isBlocking {
            focusService.stopBlocking(successful: true)
        }

        timerEngine.stopTimer()
        titleInput = ""  // Clear after stopping
        focusModeEnabled = false  // Reset for next session
    }

    private func startPlannedTask(_ task: PlannedTask) {
        // Pre-fill the title input
        titleInput = task.title

        // Start timer with task's project
        timerEngine.startTimer(
            title: task.title,
            project: task.project,
            sourcePlannedTask: task
        )
    }

    private func pauseTimer() {
        timerEngine.pauseTimer()
    }

    private func resumeTimer() {
        timerEngine.resumeTimer()
    }

    private func deleteEntry(_ entry: TimeEntry) {
        modelContext.delete(entry)
    }
}
