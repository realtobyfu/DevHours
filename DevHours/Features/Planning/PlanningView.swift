//
//  PlanningView.swift
//  DevHours
//
//  Created on 12/26/24.
//

import SwiftUI
import SwiftData

enum PlanningViewMode: String, CaseIterable {
    case calendar = "Calendar"
    case list = "List"
}

struct PlanningView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \PlannedTask.plannedDate)
    private var allPlannedTasks: [PlannedTask]

    @State private var selectedDate: Date = Date()
    @State private var showingAddSheet = false
    @State private var viewMode: PlanningViewMode = .calendar

    // Filter out completed tasks for display
    private var activeTasks: [PlannedTask] {
        allPlannedTasks.filter { !$0.isCompleted }
    }

    // Tasks for the selected date in calendar view
    private var tasksForSelectedDate: [PlannedTask] {
        activeTasks.filter {
            Calendar.current.isDate($0.plannedDate, inSameDayAs: selectedDate)
        }
    }

    // Group tasks by date for list view
    private var groupedTasks: [(Date, [PlannedTask])] {
        let grouped = Dictionary(grouping: activeTasks) { task in
            Calendar.current.startOfDay(for: task.plannedDate)
        }
        return grouped.sorted { $0.key < $1.key }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // View mode picker
                Picker("View", selection: $viewMode) {
                    ForEach(PlanningViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                if viewMode == .calendar {
                    calendarView
                } else {
                    listView
                }
            }
            .background(Color.secondarySystemBackground)
            .navigationTitle("Planning")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityLabel("Add planned task")
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                PlannedTaskEditSheet(initialDate: selectedDate, existingTask: nil)
            }
        }
    }

    private var calendarView: some View {
        VStack(spacing: 0) {
            // Calendar picker
            DatePicker(
                "Select Date",
                selection: $selectedDate,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding(.horizontal)

            Divider()

            // Tasks for selected date
            List {
                if tasksForSelectedDate.isEmpty {
                    PlanningEmptyState(date: selectedDate, onAddTask: {
                        showingAddSheet = true
                    })
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    Section {
                        ForEach(tasksForSelectedDate) { task in
                            PlannedTaskRow(task: task)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                        .onDelete { indexSet in
                            deleteTasksAtOffsets(indexSet, from: tasksForSelectedDate)
                        }
                    } header: {
                        Text(formatSectionDate(selectedDate))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    private var listView: some View {
        List {
            if groupedTasks.isEmpty {
                PlanningEmptyState(date: nil, onAddTask: {
                    showingAddSheet = true
                })
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                ForEach(groupedTasks, id: \.0) { date, tasks in
                    Section {
                        ForEach(tasks) { task in
                            PlannedTaskRow(task: task)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                        .onDelete { indexSet in
                            deleteTasksAtOffsets(indexSet, from: tasks)
                        }
                    } header: {
                        Text(formatSectionDate(date))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func formatSectionDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }

    private func deleteTasksAtOffsets(_ offsets: IndexSet, from tasks: [PlannedTask]) {
        for index in offsets {
            let task = tasks[index]
            modelContext.delete(task)
        }
        do {
            try modelContext.save()
        } catch {
            print("Error deleting planned task: \(error)")
        }
    }
}

#Preview {
    PlanningView()
        .modelContainer(for: PlannedTask.self, inMemory: true)
}
