//
//  FocusOnboardingView.swift
//  DevHours
//
//  Onboarding flow for Screen Time authorization.
//

import SwiftUI
import FamilyControls

struct FocusOnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(FocusBlockingService.self) private var focusService

    @State private var currentPage = 0
    @State private var isRequestingAuthorization = false

    var onComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Page indicator
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 20)

            TabView(selection: $currentPage) {
                // Page 1: Value Proposition
                valuePropositionPage
                    .tag(0)

                // Page 2: How It Works
                howItWorksPage
                    .tag(1)

                // Page 3: Permission Request
                permissionPage
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .interactiveDismissDisabled()
    }

    // MARK: - Page 1: Value Proposition

    private var valuePropositionPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "brain.head.profile")
                .font(.system(size: 80))
                .foregroundStyle(Color.accentColor)
                .symbolEffect(.pulse)

            VStack(spacing: 12) {
                Text("Stay in the Zone")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Apps like Instagram and TikTok are designed to capture your attention. Focus Mode helps you take it back.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            Button {
                withAnimation {
                    currentPage = 1
                }
            } label: {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Page 2: How It Works

    private var howItWorksPage: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 32) {
                howItWorksStep(
                    number: 1,
                    icon: "hand.tap",
                    title: "Pick apps to block",
                    description: "Choose categories or specific apps"
                )

                howItWorksStep(
                    number: 2,
                    icon: "play.circle.fill",
                    title: "Start a focus session",
                    description: "Blocking activates automatically"
                )

                howItWorksStep(
                    number: 3,
                    icon: "shield.fill",
                    title: "Stay focused",
                    description: "If you try to open blocked apps, you'll see a gentle reminder"
                )
            }
            .padding(.horizontal, 32)

            Spacer()

            Button {
                withAnimation {
                    currentPage = 2
                }
            } label: {
                Text("Set Up Focus Mode")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    private func howItWorksStep(number: Int, icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    // MARK: - Page 3: Permission Request

    private var permissionPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "hourglass")
                .font(.system(size: 60))
                .foregroundStyle(Color.accentColor)
                .symbolEffect(.bounce)

            VStack(spacing: 12) {
                Text("One Quick Permission")
                    .font(.title)
                    .fontWeight(.bold)

                Text("DevHours needs Screen Time access to block apps during your sessions.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Text("This stays completely on your device. We never see which apps you use.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    Task {
                        await requestAuthorization()
                    }
                } label: {
                    HStack {
                        if isRequestingAuthorization {
                            ProgressView()
                                .tint(.white)
                        }
                        Text("Allow Screen Time Access")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isRequestingAuthorization)

                Button {
                    dismiss()
                } label: {
                    Text("Skip for Now")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Authorization

    private func requestAuthorization() async {
        isRequestingAuthorization = true

        let success = await focusService.requestAuthorization()

        isRequestingAuthorization = false

        if success {
            // Create default profiles
            focusService.ensureDefaultProfiles()
            onComplete()
            dismiss()
        }
    }
}

#Preview {
    FocusOnboardingView(onComplete: {})
}
