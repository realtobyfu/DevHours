//
//  PlanningEmptyState.swift
//  DevHours
//
//  Created on 12/26/24.
//

import SwiftUI

struct PlanningEmptyState: View {
    /// The date for which there are no tasks (nil for list view)
    let date: Date?
    let onAddTask: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 4) {
                Text(messageTitle)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(messageSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                onAddTask()
            } label: {
                Label("Plan a Task", systemImage: "plus")
                    .font(.subheadline.weight(.medium))
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 40)
        .padding(.vertical, 40)
    }

    private var messageTitle: String {
        if let date = date {
            if Calendar.current.isDateInToday(date) {
                return "Nothing planned for today"
            } else if Calendar.current.isDateInTomorrow(date) {
                return "Nothing planned for tomorrow"
            } else {
                return "Nothing planned for this day"
            }
        } else {
            return "No planned tasks yet"
        }
    }

    private var messageSubtitle: String {
        if date != nil {
            return "Add a task to plan your work"
        } else {
            return "Create planned tasks to organize your time"
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        PlanningEmptyState(date: Date(), onAddTask: {})
        PlanningEmptyState(date: nil, onAddTask: {})
    }
    .padding()
}
