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

                // Timer Control Section
                EnhancedTimerCard(
                    isRunning: timerEngine?.isRunning ?? false,
                    titleInput: $titleInput,
                    elapsedTime: timerEngine?.elapsedTime ?? 0,
                    onStart: startTimer,
                    onStop: stopTimer
                )
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

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

    private func deleteEntry(_ entry: TimeEntry) {
        modelContext.delete(entry)
    }
}
