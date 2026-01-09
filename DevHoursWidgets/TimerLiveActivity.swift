//
//  TimerLiveActivity.swift
//  DevHoursWidgets
//
//  Live Activity UI for timer tracking on Lock Screen and Dynamic Island.
//

import ActivityKit
import SwiftUI
import WidgetKit

struct TimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            // Lock Screen / Banner UI
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded Dynamic Island
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.state.taskTitle.isEmpty ? "Timer" : context.state.taskTitle)
                            .font(.headline)
                            .lineLimit(1)
                        if context.state.isPaused {
                            Text("Paused")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    timerDisplay(context: context)
                        .frame(width: 90, alignment: .trailing)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        if let projectName = context.state.projectName, !projectName.isEmpty {
                            Text(projectName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()

                        // Pause/Resume button
                        Link(destination: context.state.isPaused ? DeepLink.resumeTimer : DeepLink.pauseTimer) {
                            Label(
                                context.state.isPaused ? "Resume" : "Pause",
                                systemImage: context.state.isPaused ? "play.fill" : "pause.fill"
                            )
                            .font(.caption)
                            .fontWeight(.medium)
                        }
                        .tint(context.state.isPaused ? .green : .orange)

                        // Stop button
                        Link(destination: DeepLink.stopTimer) {
                            Label("Stop", systemImage: "stop.fill")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .tint(.red)
                    }
                }
            } compactLeading: {
                // Compact leading - timer/pause icon
                Image(systemName: context.state.isPaused ? "pause.circle.fill" : "timer")
                    .font(.caption)
                    .foregroundStyle(context.state.isPaused ? .orange : .primary)
                    .padding(.leading, 4)
            } compactTrailing: {
                // Compact trailing - timer (frozen when paused)
                timerDisplay(context: context)
                    .font(.caption)
                    .fontWeight(.medium)
                    .frame(width: 50)
            } minimal: {
                // Minimal view - timer/pause icon
                Image(systemName: context.state.isPaused ? "pause.circle.fill" : "timer")
                    .font(.caption2)
                    .foregroundStyle(context.state.isPaused ? .orange : .primary)
            }
        }
    }

    @ViewBuilder
    private func timerDisplay(context: ActivityViewContext<TimerActivityAttributes>) -> some View {
        if context.state.isPaused, let elapsed = context.state.elapsedAtPause {
            // Show frozen time when paused
            Text(DurationFormatter.formatHoursMinutesSeconds(elapsed))
                .monospacedDigit()
                .foregroundStyle(.secondary)
        } else {
            // Live timer when running
            Text(context.state.startTime, style: .timer)
                .monospacedDigit()
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Lock Screen View

struct LockScreenView: View {
    let context: ActivityViewContext<TimerActivityAttributes>

    var body: some View {
        HStack(spacing: 12) {
            // Left: Title and project
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(context.state.isPaused ? Color.orange : Color.red)
                        .frame(width: 6, height: 6)
                    Text(context.state.isPaused ? "Paused" : "Time Elapsed")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(context.state.isPaused ? .orange : .red)
                }

                Text(context.state.taskTitle.isEmpty ? "Timer" : context.state.taskTitle)
                    .font(.headline)
                    .lineLimit(2)
                    .truncationMode(.tail)

                if let projectName = context.state.projectName, !projectName.isEmpty {
                    Text(projectName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .layoutPriority(1)

            Spacer()

            // Center: Timer display (frozen when paused)
            if context.state.isPaused, let elapsed = context.state.elapsedAtPause {
                Text(DurationFormatter.formatHoursMinutesSeconds(elapsed))
                    .font(.system(size: 32, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 72, alignment: .trailing)
            } else {
                Text(context.state.startTime, style: .timer)
                    .font(.system(size: 32, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .frame(minWidth: 72, alignment: .trailing)
            }

            // Right: Control buttons
            HStack(spacing: 8) {
                // Pause/Resume button
                Link(destination: context.state.isPaused ? DeepLink.resumeTimer : DeepLink.pauseTimer) {
                    Image(systemName: context.state.isPaused ? "play.circle.fill" : "pause.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(context.state.isPaused ? .green : .orange)
                }

                // Stop button
                Link(destination: DeepLink.stopTimer) {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.red)
                }
            }
        }
        .padding()
        .activityBackgroundTint(.black.opacity(0.75))
        .activitySystemActionForegroundColor(.white)
    }
}

// MARK: - Previews

#Preview("Lock Screen - Running", as: .content, using: TimerActivityAttributes(
    taskTitle: "Working on feature",
    projectName: "DevHours App"
)) {
    TimerLiveActivity()
} contentStates: {
    TimerActivityAttributes.ContentState(
        startTime: Date().addingTimeInterval(-3723),
        isRunning: true,
        isPaused: false,
        elapsedAtPause: nil,
        taskTitle: "Working on feature",
        projectName: "DevHours App"
    )
}

#Preview("Lock Screen - Paused", as: .content, using: TimerActivityAttributes(
    taskTitle: "Working on feature",
    projectName: "DevHours App"
)) {
    TimerLiveActivity()
} contentStates: {
    TimerActivityAttributes.ContentState(
        startTime: Date().addingTimeInterval(-3723),
        isRunning: false,
        isPaused: true,
        elapsedAtPause: 3723,
        taskTitle: "Working on feature",
        projectName: "DevHours App"
    )
}

#Preview("Dynamic Island Compact", as: .dynamicIsland(.compact), using: TimerActivityAttributes(
    taskTitle: "Working on feature",
    projectName: "DevHours App"
)) {
    TimerLiveActivity()
} contentStates: {
    TimerActivityAttributes.ContentState(
        startTime: Date().addingTimeInterval(-3723),
        isRunning: true,
        isPaused: false,
        elapsedAtPause: nil,
        taskTitle: "Working on feature",
        projectName: "DevHours App"
    )
}

#Preview("Dynamic Island Expanded", as: .dynamicIsland(.expanded), using: TimerActivityAttributes(
    taskTitle: "Working on feature",
    projectName: "DevHours App"
)) {
    TimerLiveActivity()
} contentStates: {
    TimerActivityAttributes.ContentState(
        startTime: Date().addingTimeInterval(-3723),
        isRunning: true,
        isPaused: false,
        elapsedAtPause: nil,
        taskTitle: "Working on feature",
        projectName: "DevHours App"
    )
}
