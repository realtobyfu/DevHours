//
//  PlannedTaskEditSheet.swift
//  DevHours
//
//  Created on 12/26/24.
//

import SwiftUI
import SwiftData

struct PlannedTaskEditSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let initialDate: Date
    let existingTask: PlannedTask?

    @Query(sort: \Project.name)
    private var projects: [Project]

    @State private var title: String = ""
    @State private var plannedDate: Date = Date()
    @State private var estimatedDuration: TimeInterval = 3600  // Default 1 hour
    @State private var selectedProject: Project?
    @State private var recurrenceFrequency: RecurrenceFrequency?
    @State private var recurrenceEndDate: Date?

    private var isEditing: Bool {
        existingTask != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                // Task Details Section
                Section {
                    TextField("What are you planning?", text: $title)

                    DatePicker(
                        "Date",
                        selection: $plannedDate,
                        displayedComponents: .date
                    )
                } header: {
                    Text("Task Details")
                }

                // Duration Section
                Section {
                    DurationPickerView(duration: $estimatedDuration)
                }

                // Project Section (optional)
                Section {
                    Picker("Project", selection: $selectedProject) {
                        Text("None").tag(nil as Project?)

                        ForEach(projects) { project in
                            Text(project.name).tag(project as Project?)
                        }
                    }
                } header: {
                    Text("Project")
                } footer: {
                    if projects.isEmpty {
                        Text("Create projects in Settings to organize your tasks.")
                    }
                }

                // Recurrence Section (only for new tasks or recurring parents)
                if !isEditing || existingTask?.isRecurringParent == true {
                    Section {
                        RecurrencePickerView(
                            frequency: $recurrenceFrequency,
                            endDate: $recurrenceEndDate
                        )
                    } header: {
                        Text("Repeat")
                    }
                }

                // Delete button for existing tasks
                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            deleteTask()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Delete Task")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Task" : "New Task")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                loadExistingTask()
            }
        }
    }

    private func loadExistingTask() {
        if let task = existingTask {
            title = task.title
            plannedDate = task.plannedDate
            estimatedDuration = task.estimatedDuration
            selectedProject = task.project
            recurrenceFrequency = task.recurrenceRule?.frequencyType
            recurrenceEndDate = task.recurrenceRule?.endDate
        } else {
            plannedDate = initialDate
        }
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)

        // Normalize date to noon to avoid timezone issues
        let calendar = Calendar.current
        let normalizedDate = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: plannedDate) ?? plannedDate

        if let task = existingTask {
            // Update existing task
            task.title = trimmedTitle
            task.plannedDate = normalizedDate
            task.estimatedDuration = estimatedDuration
            task.project = selectedProject

            // Update recurrence rule if this is a recurring parent
            if task.isRecurringParent {
                if let freq = recurrenceFrequency {
                    if let rule = task.recurrenceRule {
                        rule.frequency = freq.rawValue
                        rule.endDate = recurrenceEndDate
                    }
                } else {
                    // Remove recurrence
                    if let rule = task.recurrenceRule {
                        modelContext.delete(rule)
                    }
                    task.recurrenceRule = nil
                }
            }
        } else {
            // Create new task
            var recurrenceRule: RecurrenceRule?
            if let freq = recurrenceFrequency {
                recurrenceRule = RecurrenceRule(
                    frequency: freq,
                    endDate: recurrenceEndDate
                )
                modelContext.insert(recurrenceRule!)
            }

            let newTask = PlannedTask(
                title: trimmedTitle,
                plannedDate: normalizedDate,
                estimatedDuration: estimatedDuration,
                project: selectedProject,
                recurrenceRule: recurrenceRule
            )
            modelContext.insert(newTask)
        }

        do {
            try modelContext.save()
            SharedDataManager.shared.updateWidgetData()
        } catch {
            print("Error saving planned task: \(error)")
        }

        dismiss()
    }

    private func deleteTask() {
        if let task = existingTask {
            // Also delete recurrence rule if present
            if let rule = task.recurrenceRule {
                modelContext.delete(rule)
            }
            modelContext.delete(task)

            do {
                try modelContext.save()
                SharedDataManager.shared.updateWidgetData()
            } catch {
                print("Error deleting planned task: \(error)")
            }
        }
        dismiss()
    }
}

#Preview("New Task") {
    PlannedTaskEditSheet(initialDate: Date(), existingTask: nil)
        .modelContainer(for: [PlannedTask.self, Project.self], inMemory: true)
}
