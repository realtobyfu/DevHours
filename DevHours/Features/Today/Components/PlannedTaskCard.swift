//
//  PlannedTaskCard.swift
//  DevHours
//
//  Created on 12/26/24.
//

import SwiftUI
import SwiftData

struct PlannedTaskCard: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var task: PlannedTask

    let onStart: (PlannedTask) -> Void

    @State private var showingEditSheet = false
    @State private var showingMenu = false

    var body: some View {
        HStack(spacing: 16) {
            // Task details on the left
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(task.title.isEmpty ? "Untitled Task" : task.title)
                        .font(.headline)
                        .lineLimit(2)
                        .layoutPriority(1)

                    Spacer(minLength: 8)

                    if !task.tags.isEmpty {
                        TagsFlowView(tags: task.tags, compact: true)
                    }
                }

                HStack(spacing: 8) {
                    // Remaining duration (or full estimate if not started)
                    if task.workedDuration > 0 {
                        Label(
                            "\(DurationFormatter.formatHoursMinutes(task.remainingDuration)) left",
                            systemImage: "clock"
                        )
                        .font(.subheadline)
                        .foregroundStyle(task.remainingDuration > 0 ? Color.secondary : Color.green)
                    } else {
                        Label(
                            DurationFormatter.formatHoursMinutes(task.estimatedDuration),
                            systemImage: "clock"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }

                    // Project name (subtle)
                    if let project = task.project {
                        Text("(\(project.name))")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }

            }

            Spacer()

            // More options menu
            Menu {
                Button {
                    showingEditSheet = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }

                Button {
                    markComplete()
                } label: {
                    Label("Complete without Tracking", systemImage: "checkmark")
                }

                Divider()

                Button(role: .destructive) {
                    deleteTask()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            // Round Start Button on the right
            Button {
                onStart(task)
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 56, height: 56)
                        .shadow(color: Color.accentColor.opacity(0.3), radius: 6, y: 3)

                    Image(systemName: "play.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Start \(task.title)")
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.systemBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.accentColor.opacity(0.2), lineWidth: 1)
        )
        .sheet(isPresented: $showingEditSheet) {
            PlannedTaskEditSheet(initialDate: task.plannedDate, existingTask: task)
        }
    }

    private func markComplete() {
        task.isCompleted = true
        task.completedAt = Date.now

        do {
            try modelContext.save()
        } catch {
            print("Error marking task complete: \(error)")
        }
    }

    private func deleteTask() {
        if let rule = task.recurrenceRule {
            modelContext.delete(rule)
        }
        modelContext.delete(task)

        do {
            try modelContext.save()
        } catch {
            print("Error deleting task: \(error)")
        }
    }
}
