//
//  FocusOnboardingView.swift
//  DevHours
//
//  Onboarding flow for Screen Time authorization.
//

import SwiftUI
#if !os(macOS)
import FamilyControls
#endif

#if !os(macOS)
struct FocusOnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(FocusBlockingService.self) private var focusService

    @State private var currentPage = 0
    @State private var isRequestingAuthorization = false
    @State private var showingSuccessPage = false
    @State private var showingSkipConfirmation = false

    var onComplete: () -> Void

    // Key for tracking onboarding completion
    static let hasCompletedOnboardingKey = "hasCompletedFocusOnboarding"

    static var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: hasCompletedOnboardingKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasCompletedOnboardingKey) }
    }

    private var totalPages: Int {
        showingSuccessPage ? 4 : 3
    }

    var body: some View {
        VStack(spacing: 0) {
            // Page indicator
            HStack(spacing: 8) {
                ForEach(0..<totalPages, id: \.self) { index in
                    Circle()
                        .fill(index == currentPage ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .accessibilityHidden(true)
                }
            }
            .padding(.top, 20)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Page \(currentPage + 1) of \(totalPages)")

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

                // Page 4: Success (only shown after authorization)
                if showingSuccessPage {
                    successPage
                        .tag(3)
                }
            }
            #if os(iOS)
            .tabViewStyle(.page(indexDisplayMode: .never))
            #else
            .tabViewStyle(.automatic)
            #endif
        }
        .interactiveDismissDisabled()
        .alert("Skip Focus Mode Setup?", isPresented: $showingSkipConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Skip", role: .destructive) {
                // Mark as completed so we don't show again
                Self.hasCompletedOnboarding = true
                dismiss()
            }
        } message: {
            Text("You can always set up Focus Mode later in Settings.")
        }
    }

    // MARK: - Page 1: Value Proposition

    private var valuePropositionPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "brain.head.profile")
                .font(.system(size: 80, weight: .medium))
                .foregroundStyle(Color.accentColor)
                .symbolEffect(.pulse)
                .accessibilityHidden(true)

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
            .accessibilityLabel("Continue to next page")
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
            .accessibilityLabel("Continue to permission request")
        }
    }

    private func howItWorksStep(number: Int, icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.title2.weight(.medium))
                    .foregroundStyle(Color.accentColor)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(number): \(title). \(description)")
    }

    // MARK: - Page 3: Permission Request

    private var permissionPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "moon.fill")
                .font(.system(size: 60, weight: .medium))
                .foregroundStyle(Color.accentColor)
                .symbolEffect(.bounce)
                .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text("One Quick Permission")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Clockwise needs Screen Time access to block apps during your sessions.")
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
                .accessibilityLabel("Allow Screen Time access")
                .accessibilityHint("Opens system permission dialog")

                Button {
                    showingSkipConfirmation = true
                } label: {
                    Text("Skip for Now")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Skip Focus Mode setup")
                .accessibilityHint("You can set up Focus Mode later in Settings")
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Page 4: Success

    private var successPage: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60, weight: .medium))
                    .foregroundStyle(.green)
                    .symbolEffect(.bounce, value: showingSuccessPage)
            }
            .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text("You're All Set!")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Focus Mode is ready. When you start a timer, you can enable Focus Mode to block distracting apps.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            Button {
                // Mark as completed
                Self.hasCompletedOnboarding = true
                onComplete()
                dismiss()
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .accessibilityLabel("Get started with Focus Mode")
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

            // Show success page
            withAnimation {
                showingSuccessPage = true
                currentPage = 3
            }
        }
    }
}

#Preview {
    FocusOnboardingView(onComplete: {})
}
#else
struct FocusOnboardingView: View {
    @Environment(\.dismiss) private var dismiss

    var onComplete: () -> Void

    static let hasCompletedOnboardingKey = "hasCompletedFocusOnboarding"

    static var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: hasCompletedOnboardingKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasCompletedOnboardingKey) }
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "iphone")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Focus Mode setup happens on iPhone or iPad.")
                .font(.headline)
                .multilineTextAlignment(.center)

            Text("Once enabled on iOS, your focus profiles will sync here.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            Button("Done") {
                Self.hasCompletedOnboarding = true
                onComplete()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(32)
        .frame(minWidth: 300, minHeight: 250)
    }
}

#Preview {
    FocusOnboardingView(onComplete: {})
}
#endif
