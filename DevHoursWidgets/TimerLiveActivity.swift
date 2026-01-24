//
//  TimerLiveActivity.swift
//  DevHoursWidgets
//
//  Live Activity UI for timer tracking on Lock Screen and Dynamic Island.
//

#if !os(macOS)
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
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(width: 90, alignment: .trailing)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
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
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(width: 55)
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
        Group {
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
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
}

// MARK: - Lock Screen View

struct LockScreenView: View {
    let context: ActivityViewContext<TimerActivityAttributes>

    var body: some View {
        HStack(spacing: 16) {
            // Left: Recording indicator + Title
            HStack(spacing: 8) {
                Circle()
                    .fill(context.state.isPaused ? Color.orange : Color.red)
                    .frame(width: 8, height: 8)

                Text(context.state.taskTitle.isEmpty ? "Timer" : context.state.taskTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }

            Spacer()

            // Timer display
            Group {
                if context.state.isPaused, let elapsed = context.state.elapsedAtPause {
                    Text(DurationFormatter.formatHoursMinutesSeconds(elapsed))
                        .foregroundStyle(.secondary)
                } else {
                    Text(context.state.startTime, style: .timer)
                        .foregroundStyle(.primary)
                }
            }
            .font(.system(size: 20, weight: .semibold, design: .rounded))
            .monospacedDigit()

            // Control buttons
            HStack(spacing: 6) {
                Link(destination: context.state.isPaused ? DeepLink.resumeTimer : DeepLink.pauseTimer) {
                    Image(systemName: context.state.isPaused ? "play.circle.fill" : "pause.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(context.state.isPaused ? .green : .orange)
                }

                Link(destination: DeepLink.stopTimer) {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .activityBackgroundTint(.black.opacity(0.8))
        .activitySystemActionForegroundColor(.white)
    }
}

// MARK: - Previews

#Preview("Lock Screen - Running", as: .content, using: TimerActivityAttributes(
    taskTitle: "Working on feature"
)) {
    TimerLiveActivity()
} contentStates: {
    TimerActivityAttributes.ContentState(
        startTime: Date().addingTimeInterval(-3723),
        isRunning: true,
        isPaused: false,
        elapsedAtPause: nil,
        taskTitle: "Working on feature"
    )
}

//#Preview("Lock Screen - Paused", as: .content, using: TimerActivityAttributes(
//    taskTitle: "Working on feature",
//    projectName: "DevHours App"
//)) {
//    TimerLiveActivity()
//} contentStates: {
//    TimerActivityAttributes.ContentState(
//        startTime: Date().addingTimeInterval(-3723),
//        isRunning: false,
//        isPaused: true,
//        elapsedAtPause: 3723,
//        taskTitle: "Working on feature",
//        projectName: "DevHours App"
//    )
//}
//
//#Preview("Dynamic Island Compact", as: .dynamicIsland(.compact), using: TimerActivityAttributes(
//    taskTitle: "Working on feature",
//    projectName: "DevHours App"
//)) {
//    TimerLiveActivity()
//} contentStates: {
//    TimerActivityAttributes.ContentState(
//        startTime: Date().addingTimeInterval(-3723),
//        isRunning: true,
//        isPaused: false,
//        elapsedAtPause: nil,
//        taskTitle: "Working on feature",
//        projectName: "DevHours App"
//    )
//}
//
//#Preview("Dynamic Island Expanded", as: .dynamicIsland(.expanded), using: TimerActivityAttributes(
//    taskTitle: "Working on feature",
//    projectName: "DevHours App"
//)) {
//    TimerLiveActivity()
//} contentStates: {
//    TimerActivityAttributes.ContentState(
//        startTime: Date().addingTimeInterval(-3723),
//        isRunning: true,
//        isPaused: false,
//        elapsedAtPause: nil,
//        taskTitle: "Working on feature",
//        projectName: "DevHours App"
//    )
//}
#endif
