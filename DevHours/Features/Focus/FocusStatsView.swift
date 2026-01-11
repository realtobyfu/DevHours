//
//  FocusStatsView.swift
//  DevHours
//
//  Displays focus statistics, streaks, and achievements.
//

import SwiftUI
import SwiftData

struct FocusStatsView: View {
    @Environment(FocusBlockingService.self) private var focusService
    @Environment(PremiumManager.self) private var premiumManager

    @Query private var stats: [FocusStats]

    private var currentStats: FocusStats? {
        stats.first
    }

    var body: some View {
        List {
            if premiumManager.isPremium {
                // Streak Section
                Section {
                    StreakCard(stats: currentStats)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                // Stats Summary
                Section("This Week") {
                    StatsRow(
                        icon: "clock.fill",
                        color: .blue,
                        title: "Focus Time",
                        value: formatDuration(currentStats?.totalFocusSeconds ?? 0)
                    )

                    StatsRow(
                        icon: "checkmark.circle.fill",
                        color: .green,
                        title: "Sessions Completed",
                        value: "\(currentStats?.totalSessionsCompleted ?? 0)"
                    )

                    StatsRow(
                        icon: "hand.raised.fill",
                        color: .orange,
                        title: "Override Count",
                        value: "\(currentStats?.totalOverrides ?? 0)"
                    )
                }

                // Achievements Section
                Section("Achievements") {
                    ForEach(Achievement.all) { achievement in
                        AchievementRow(
                            achievement: achievement,
                            isUnlocked: currentStats?.unlockedAchievements.contains(achievement.id) ?? false
                        )
                    }
                }
            } else {
                // Premium upsell
                Section {
                    PremiumUpsellCard()
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                // Teaser stats (blurred/locked)
                Section("Preview") {
                    StatsRow(
                        icon: "clock.fill",
                        color: .blue,
                        title: "Focus Time",
                        value: "??:??",
                        isLocked: true
                    )

                    StatsRow(
                        icon: "flame.fill",
                        color: .orange,
                        title: "Current Streak",
                        value: "? days",
                        isLocked: true
                    )

                    StatsRow(
                        icon: "trophy.fill",
                        color: .yellow,
                        title: "Achievements",
                        value: "?/\(Achievement.all.count)",
                        isLocked: true
                    )
                }
            }
        }
        .navigationTitle("Focus Statistics")
        #if os(iOS) && !targetEnvironment(macCatalyst)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Streak Card

struct StreakCard: View {
    let stats: FocusStats?

    var body: some View {
        VStack(spacing: 16) {
            // Streak flame
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(streakColor)
                    .symbolEffect(.bounce, value: stats?.currentStreak ?? 0)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(stats?.currentStreak ?? 0)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))

                    Text("day streak")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            // Best streak
            if let longest = stats?.longestStreak, longest > 0 {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(.yellow)
                    Text("Best: \(longest) days")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.orange.opacity(0.1))
        )
        .padding(.horizontal)
    }

    private var streakColor: Color {
        guard let streak = stats?.currentStreak else { return .gray }
        switch streak {
        case 0: return .gray
        case 1...6: return .orange
        case 7...29: return .red
        default: return .purple
        }
    }
}

// MARK: - Stats Row

struct StatsRow: View {
    let icon: String
    let color: Color
    let title: String
    let value: String
    var isLocked: Bool = false

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(isLocked ? .gray : color)
                .frame(width: 30)

            Text(title)
                .foregroundStyle(isLocked ? .secondary : .primary)

            Spacer()

            Text(value)
                .font(.headline)
                .foregroundStyle(isLocked ? .secondary : .primary)
                .blur(radius: isLocked ? 4 : 0)

            if isLocked {
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Achievement Row

struct AchievementRow: View {
    let achievement: Achievement
    let isUnlocked: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? Color.yellow.opacity(0.2) : Color.secondary.opacity(0.1))
                    .frame(width: 44, height: 44)

                Image(systemName: achievement.iconName)
                    .font(.title3)
                    .foregroundStyle(isUnlocked ? .yellow : .secondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.name)
                    .font(.headline)
                    .foregroundStyle(isUnlocked ? .primary : .secondary)

                Text(achievement.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .opacity(isUnlocked ? 1 : 0.6)
    }
}

// MARK: - Premium Upsell Card

struct PremiumUpsellCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.accentColor)

            Text("Unlock Focus Statistics")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Track your streaks, see your focus patterns, and unlock achievements with Premium.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                // TODO: Show paywall
            } label: {
                Text("Learn More")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.accentColor.opacity(0.1))
        )
        .padding(.horizontal)
    }
}

// MARK: - Streak Badge (for Today tab header)

struct StreakBadge: View {
    let streak: Int

    var body: some View {
        if streak > 0 {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text("\(streak)")
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.orange.opacity(0.15))
            )
        }
    }
}

#Preview {
    NavigationStack {
        FocusStatsView()
    }
}
