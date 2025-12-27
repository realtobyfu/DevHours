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

    // Query all entries, then filter for today in Swift code
    @Query(sort: \TimeEntry.startTime, order: .reverse)
    private var allEntries: [TimeEntry]

    // Query all planned tasks, then filter for today
    @Query(sort: \PlannedTask.estimatedDuration, order: .reverse)
    private var allPlannedTasks: [PlannedTask]

    @State private var timerEngine: TimerEngine?
    @State private var titleInput = ""

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
        timerEngine?.runningEntry?.sourcePlannedTask != nil
    }

    // Get the currently running planned task (if any)
    private var runningPlannedTask: PlannedTask? {
        timerEngine?.runningEntry?.sourcePlannedTask
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
                            isRunning: true,
                            elapsedTime: timerEngine?.elapsedTime ?? 0,
                            onStart: startPlannedTask,
                            onStop: stopTimer,
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
                        isRunning: timerEngine?.isRunning ?? false,
                        isLocked: false,
                        titleInput: $titleInput,
                        elapsedTime: timerEngine?.elapsedTime ?? 0,
                        onStart: startTimer,
                        onStop: stopTimer
                    )
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                
                // Planned Tasks Section (hidden when any timer is running)
                if !todayPlannedTasks.isEmpty && !(timerEngine?.isRunning ?? false) {
                    Section {
                        if todayPlannedTasks.count == 2 {
                            // Two tasks: side-by-side compact layout
                            HStack(spacing: 12) {
                                ForEach(Array(todayPlannedTasks.enumerated()), id: \.element.id) { index, task in
                                    TimerCardContainer(
                                        task: task,
                                        isRunning: false,
                                        elapsedTime: 0,
                                        onStart: startPlannedTask,
                                        onStop: stopTimer,
                                        tintColor: TimerCardContainer.cardTints[index % TimerCardContainer.cardTints.count],
                                        isCompact: true
                                    )
                                }
                            }
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        } else {
                            // 1 or 3+ tasks: vertical stack with full cards
                            ForEach(Array(todayPlannedTasks.enumerated()), id: \.element.id) { index, task in
                                TimerCardContainer(
                                    task: task,
                                    isRunning: false,
                                    elapsedTime: 0,
                                    onStart: startPlannedTask,
                                    onStop: stopTimer,
                                    tintColor: TimerCardContainer.cardTints[index % TimerCardContainer.cardTints.count]
                                )
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }
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
                } else if timerEngine?.isRunning == false {
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
        .onAppear {
            if timerEngine == nil {
                timerEngine = TimerEngine(modelContext: modelContext)
            }
        }
        .onChange(of: titleInput) { _, newValue in
            timerEngine?.updateTitle(newValue)
        }
    }

    // MARK: - Actions
    private func startTimer() {
        timerEngine?.startTimer(title: titleInput)
        // Keep titleInput so user can continue editing while timer runs
    }

    private func stopTimer() {
        timerEngine?.stopTimer()
        titleInput = ""  // Clear after stopping
    }

    private func startPlannedTask(_ task: PlannedTask) {
        // Pre-fill the title input
        titleInput = task.title

        // Start timer with task's project
        timerEngine?.startTimer(
            title: task.title,
            project: task.project,
            sourcePlannedTask: task
        )
    }

    private func deleteEntry(_ entry: TimeEntry) {
        modelContext.delete(entry)
    }
}
