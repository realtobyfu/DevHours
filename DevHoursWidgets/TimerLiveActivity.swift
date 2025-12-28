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
                    Text(context.attributes.taskTitle.isEmpty ? "Timer" : context.attributes.taskTitle)
                        .font(.headline)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.startTime, style: .timer)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                        .frame(width: 90, alignment: .trailing)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        if let projectName = context.attributes.projectName, !projectName.isEmpty {
                            Text(projectName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Link(destination: DeepLink.stopTimer) {
                            Label("Stop", systemImage: "stop.fill")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .tint(.red)
                    }
                }
            } compactLeading: {
                // Compact leading - timer icon
                Image(systemName: "timer")
                    .font(.caption)
                    .padding(.leading, 4)
            } compactTrailing: {
                // Compact trailing - timer
                Text(context.state.startTime, style: .timer)
                    .font(.caption)
                    .fontWeight(.medium)
                    .monospacedDigit()
                    .frame(width: 50)
            } minimal: {
                // Minimal view - timer icon
                Image(systemName: "timer")
                    .font(.caption2)
            }
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
                Text(context.attributes.taskTitle.isEmpty ? "Timer" : context.attributes.taskTitle)
                    .font(.headline)
                    .lineLimit(1)

                if let projectName = context.attributes.projectName, !projectName.isEmpty {
                    Text(projectName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Center: Timer display
            Text(context.state.startTime, style: .timer)
                .font(.system(size: 32, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)

            // Right: Stop button
            Link(destination: DeepLink.stopTimer) {
                Image(systemName: "stop.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .activityBackgroundTint(.black.opacity(0.75))
        .activitySystemActionForegroundColor(.white)
    }
}

// MARK: - Previews

#Preview("Lock Screen", as: .content, using: TimerActivityAttributes(
    taskTitle: "Working on feature",
    projectName: "DevHours App"
)) {
    TimerLiveActivity()
} contentStates: {
    TimerActivityAttributes.ContentState(
        startTime: Date().addingTimeInterval(-3723),
        isRunning: true
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
        isRunning: true
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
        isRunning: true
    )
}
