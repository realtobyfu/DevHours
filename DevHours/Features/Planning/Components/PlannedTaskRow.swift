//
//  PlannedTaskRow.swift
//  DevHours
//
//  Created on 12/26/24.
//

import SwiftUI
import SwiftData

struct PlannedTaskRow: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var task: PlannedTask

    @State private var showingEditSheet = false

    var body: some View {
        HStack(spacing: 12) {
//            // Completion checkbox
//            Button {
//                toggleCompletion()
//            } label: {
//                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
//                    .font(.title2)
//                    .foregroundStyle(task.isCompleted ? .green : .secondary)
//            }
//            .buttonStyle(.plain)
//            .accessibilityLabel(task.isCompleted ? "Mark incomplete" : "Mark complete")

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title.isEmpty ? "Untitled Task" : task.title)
                    .font(.headline)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)

                HStack(spacing: 8) {
                    // Duration estimate
                    Label(
                        DurationFormatter.formatHoursMinutes(task.estimatedDuration),
                        systemImage: "clock"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    // Recurrence indicator
                    if task.recurrenceRule != nil || task.parentTaskId != nil {
                        Image(systemName: "repeat")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }

                    // Overdue indicator
                    if task.isOverdue {
                        Label("Overdue", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                // Project if set
                if let project = task.project {
                    Text(project.name)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            // Chevron to indicate tappable
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.systemBackground)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            showingEditSheet = true
        }
        .sheet(isPresented: $showingEditSheet) {
            PlannedTaskEditSheet(initialDate: task.plannedDate, existingTask: task)
        }
    }

//    private func toggleCompletion() {
//        task.isCompleted.toggle()
//        if task.isCompleted {
//            task.completedAt = Date.now
//        } else {
//            task.completedAt = nil
//        }
//
//        do {
//            try modelContext.save()
//        } catch {
//            print("Error toggling task completion: \(error)")
//        }
//    }
}
