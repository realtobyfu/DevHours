//
//  EnhancedTimerCard.swift
//  DevHours
//
//  Created on 12/13/24.
//

import SwiftUI

struct EnhancedTimerCard: View {
    let isRunning: Bool
    let isLocked: Bool
    @Binding var titleInput: String
    let elapsedTime: TimeInterval
    let onStart: () -> Void
    let onStop: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Hero Timer Display (when running)
            if isRunning {
                VStack(spacing: 8) {
                    Text(DurationFormatter.formatHoursMinutesSeconds(elapsedTime))
                        .font(.system(size: 64, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                        .monospacedDigit()
                        .transition(.scale.combined(with: .opacity))
                        .accessibilityLabel("Elapsed time: \(DurationFormatter.formatAccessible(elapsedTime))")

                    Text("Time tracking in progress")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 20)
            }

            // Title Input with enhanced styling
            VStack(alignment: .leading, spacing: 8) {
                if isRunning {
                    Text("What are you working on?")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                }

                TextField("What are you working on?", text: $titleInput)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .fontWeight(isRunning ? .semibold : .regular)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.systemGray6)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                isRunning ? Color.accentColor.opacity(0.3) : Color.clear,
                                lineWidth: 2
                            )
                    )
                    .disabled(isLocked)
                    .opacity(isLocked ? 0.6 : 1.0)
                    .accessibilityLabel("Timer title")
            }

            // Enhanced Start/Stop Button
            Button(action: isRunning ? onStop : onStart) {
                Label(
                    isRunning ? "Stop Timer" : "Start Timer",
                    systemImage: isRunning ? "stop.fill" : "play.fill"
                )
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(buttonGradient)
                        .shadow(color: buttonShadowColor, radius: 8, y: 4)
                )
                .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isRunning ? "Stop timer" : "Start timer")
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.systemBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
        )
        .frame(maxWidth: 500)
        .frame(maxWidth: .infinity, alignment: .center)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isRunning)
    }

    private var buttonGradient: LinearGradient {
        if isRunning {
            return LinearGradient(
                colors: [Color.red.opacity(0.9), Color.red],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Color.green.opacity(0.9), Color.green],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var buttonShadowColor: Color {
        isRunning ? Color.red.opacity(0.3) : Color.green.opacity(0.3)
    }
}
