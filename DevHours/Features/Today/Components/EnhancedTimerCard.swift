//
//  EnhancedTimerCard.swift
//  DevHours
//
//  Created on 12/13/24.
//

import SwiftUI

struct EnhancedTimerCard: View {
    let isRunning: Bool
    let isPaused: Bool
    let isLocked: Bool
    @Binding var titleInput: String
    let elapsedTime: TimeInterval
    let onStart: () -> Void
    let onStop: () -> Void
    let onPause: () -> Void
    let onResume: () -> Void

    /// True if there's an active timer (running or paused)
    private var hasActiveTimer: Bool {
        isRunning || isPaused
    }

    var body: some View {
        VStack(spacing: 20) {
            // Hero Timer Display (when running or paused)
            if hasActiveTimer {
                VStack(spacing: 8) {
                    Text(DurationFormatter.formatHoursMinutesSeconds(elapsedTime))
                        .font(.system(size: 64, weight: .semibold, design: .rounded))
                        .foregroundStyle(isPaused ? .secondary : .primary)
                        .monospacedDigit()
                        .transition(.scale.combined(with: .opacity))
                        .accessibilityLabel("Elapsed time: \(DurationFormatter.formatAccessible(elapsedTime))")

                    // Status indicator
                    HStack(spacing: 6) {
                        if isPaused {
//                            Image(systemName: "pause.circle.fill")
//                                .foregroundStyle(.orange)
                            Text("Paused")
                                .foregroundStyle(.orange)
                        } else {
                            Text("Time tracking in progress")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .font(.subheadline)
                }
                .padding(.vertical, 20)
            }

            // Title Input with enhanced styling
            VStack(alignment: .leading, spacing: 8) {
                if hasActiveTimer {
                    Text("What are you working on?")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                }

                TextField("What are you working on?", text: $titleInput)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .fontWeight(hasActiveTimer ? .semibold : .regular)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.systemGray6)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                hasActiveTimer ? Color.accentColor.opacity(0.3) : Color.clear,
                                lineWidth: 2
                            )
                    )
                    .disabled(isLocked)
                    .opacity(isLocked ? 0.6 : 1.0)
                    .accessibilityLabel("Timer title")
            }

            // Timer Control Buttons
            if hasActiveTimer {
                // Show Pause/Resume and Stop buttons side by side
                HStack(spacing: 12) {
                    // Pause/Resume Button
                    Button(action: isPaused ? onResume : onPause) {
                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                            .font(.headline)
                            .frame(width: 52, height: 52)
                            .background(
                                Circle()
                                    .fill(isPaused ? greenGradient : orangeGradient)
                                    .shadow(color: isPaused ? .green.opacity(0.3) : .orange.opacity(0.3), radius: 8, y: 4)
                            )
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .layoutPriority(0)
                    .accessibilityLabel(isPaused ? "Resume timer" : "Pause timer")

                    // Stop Button
                    Button(action: onStop) {
                        Label("Stop", systemImage: "stop.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(redGradient)
                                    .shadow(color: .red.opacity(0.3), radius: 8, y: 4)
                            )
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Stop timer")
                }
            } else {
                // Start Button
                Button(action: onStart) {
                    Label("Start Timer", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(greenGradient)
                                .shadow(color: .green.opacity(0.3), radius: 8, y: 4)
                        )
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Start timer")
            }
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
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isPaused)
    }

    private var greenGradient: LinearGradient {
        LinearGradient(
            colors: [Color.green.opacity(0.9), Color.green],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var orangeGradient: LinearGradient {
        LinearGradient(
            colors: [Color.orange.opacity(0.9), Color.orange],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var redGradient: LinearGradient {
        LinearGradient(
            colors: [Color.red.opacity(0.9), Color.red],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
