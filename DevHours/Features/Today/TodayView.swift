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

    @State private var timerEngine: TimerEngine?
    @State private var titleInput = ""

    // Filter for today's entries (Calendar methods not supported in @Query predicates)
    private var todayEntries: [TimeEntry] {
        allEntries.filter { Calendar.current.isDateInToday($0.startTime) }
    }

    // Total duration for summary header
    private var totalDurationToday: TimeInterval {
        todayEntries.reduce(0) { $0 + $1.duration }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Daily Summary (only show if there are entries)
                    if !todayEntries.isEmpty {
                        DailySummaryHeader(
                            totalDuration: totalDurationToday,
                            entryCount: todayEntries.count
                        )
                        .padding(.horizontal, 16)
                    }

                    // Enhanced Timer Control Card
                    EnhancedTimerCard(
                        isRunning: timerEngine?.isRunning ?? false,
                        titleInput: $titleInput,
                        elapsedTime: timerEngine?.elapsedTime ?? 0,
                        onStart: startTimer,
                        onStop: stopTimer
                    )
                    .padding(.horizontal, 16)

                    // Today's Entries Section
                    VStack(alignment: .leading, spacing: 12) {
                        if !todayEntries.isEmpty {
                            Text("Today's Entries")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 16)

                            LazyVStack(spacing: 12) {
                                ForEach(todayEntries) { entry in
                                    TodayEntryRow(entry: entry)
                                        .padding(.horizontal, 16)
                                }
                            }
                        } else if timerEngine?.isRunning == false {
                            EmptyTodayState()
                        }
                    }
                    .padding(.bottom, 20)
                }
                .padding(.top, 8)
            }
            .background(Color(.secondarySystemBackground))
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
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
}
