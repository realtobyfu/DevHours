//
//  TimerCardContainer.swift
//  DevHours
//
//  Created on 12/26/24.
//

import SwiftUI
import SwiftData

/// A unified card that morphs between planned task and running timer states
struct TimerCardContainer: View {
    @Environment(\.modelContext) private var modelContext

    let task: PlannedTask?
    let isRunning: Bool
    let elapsedTime: TimeInterval
    let onStart: (PlannedTask) -> Void
    let onStop: () -> Void
    var tintColor: Color = .blue
    var isCompact: Bool = false

    @Namespace private var animation
    @State private var showingEditSheet = false

    // Color palette for multi-task differentiation
    static let cardTints: [Color] = [.blue, .purple, .orange, .teal]

    var body: some View {
        VStack(spacing: 0) {
            if isRunning, let task {
                runningCard(task)
            } else if let task {
                plannedCard(task)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isRunning)
    }

    // MARK: - Planned State

    private func plannedCard(_ task: PlannedTask) -> some View {
        HStack(spacing: isCompact ? 10 : 16) {
            VStack(alignment: .leading, spacing: isCompact ? 4 : 6) {
                Text(task.title.isEmpty ? "Untitled Task" : task.title)
                    .font(isCompact ? .subheadline.weight(.semibold) : .headline)
                    .lineLimit(isCompact ? 1 : 2)
                    .matchedGeometryEffect(id: "title-\(task.id)", in: animation)

                if isCompact {
                    // Compact: just duration below title
                    durationChip(task)
                        .matchedGeometryEffect(id: "duration-\(task.id)", in: animation)
                } else {
                    // Full: duration + project in HStack
                    HStack(spacing: 8) {
                        durationChip(task)
                            .matchedGeometryEffect(id: "duration-\(task.id)", in: animation)

                        if let project = task.project {
                            Text(project.name)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.secondary.opacity(0.1))
                                )
                        }
                    }
                }
            }

            Spacer(minLength: 4)

            // Play button
            Button {
                onStart(task)
            } label: {
                Circle()
                    .fill(tintColor)
                    .frame(width: isCompact ? 40 : 48, height: isCompact ? 40 : 48)
                    .shadow(color: tintColor.opacity(0.3), radius: 6, y: 3)
                    .overlay(
                        Image(systemName: "play.fill")
                            .font(isCompact ? .body : .title3)
                            .foregroundStyle(.white)
                    )
            }
            .buttonStyle(.plain)
            .transition(.scale.combined(with: .opacity))
            .accessibilityLabel("Start \(task.title)")
        }
        .padding(isCompact ? 12 : 16)
        .background(cardBackground)
        .contextMenu {
            Button {
                showingEditSheet = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }

            Button {
                markComplete(task)
            } label: {
                Label("Complete without Tracking", systemImage: "checkmark")
            }

            Divider()

            Button(role: .destructive) {
                deleteTask(task)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            PlannedTaskEditSheet(initialDate: task.plannedDate, existingTask: task)
        }
    }

    // MARK: - Running State

    private func runningCard(_ task: PlannedTask) -> some View {
        VStack(spacing: 16) {
            // Title (centered)
            Text(task.title.isEmpty ? "Untitled Task" : task.title)
                .font(.title3.bold())
                .multilineTextAlignment(.center)
                .matchedGeometryEffect(id: "title-\(task.id)", in: animation)

            // Timer display
            Text(DurationFormatter.formatHoursMinutesSeconds(elapsedTime))
                .font(.system(size: 56, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
                .monospacedDigit()
                .transition(.scale(scale: 0.8).combined(with: .opacity))
                .accessibilityLabel("Elapsed time: \(DurationFormatter.formatAccessible(elapsedTime))")

            // Remaining duration
            durationChip(task, showRemaining: true)
                .matchedGeometryEffect(id: "duration-\(task.id)", in: animation)

            // Stop button
            Button(action: onStop) {
                Label("Stop Timer", systemImage: "stop.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [Color.red.opacity(0.9), Color.red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.red.opacity(0.3), radius: 8, y: 4)
                    )
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .accessibilityLabel("Stop timer")
        }
        .padding(20)
        .background(cardBackground)
    }

    // MARK: - Shared Components

    private func durationChip(_ task: PlannedTask, showRemaining: Bool = false) -> some View {
        Group {
            if showRemaining || task.workedDuration > 0 {
                Label(
                    "\(DurationFormatter.formatHoursMinutes(task.remainingDuration))",
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
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.systemBackground)
            .shadow(color: Color.black.opacity(0.06), radius: 8, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(tintColor.opacity(0.3), lineWidth: 1.5)
            )
    }

    // MARK: - Actions

    private func markComplete(_ task: PlannedTask) {
        task.isCompleted = true
        task.completedAt = Date.now
        try? modelContext.save()
    }

    private func deleteTask(_ task: PlannedTask) {
        if let rule = task.recurrenceRule {
            modelContext.delete(rule)
        }
        modelContext.delete(task)
        try? modelContext.save()
    }
}
