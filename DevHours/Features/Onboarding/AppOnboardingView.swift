//
//  AppOnboardingView.swift
//  DevHours
//
//  General onboarding flow for first-time app users.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
private typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit
private typealias PlatformImage = NSImage
#endif

struct AppOnboardingView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var currentPage = 0

    var onComplete: () -> Void

    // Key for tracking onboarding completion
    static let hasCompletedOnboardingKey = "hasCompletedAppOnboarding"

    static var hasCompletedOnboarding: Bool {
        get { UserDefaults.standard.bool(forKey: hasCompletedOnboardingKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasCompletedOnboardingKey) }
    }

    private let totalPages = 3

    var body: some View {
        VStack(spacing: 0) {
            #if os(iOS)
            // Page indicator
            HStack(spacing: 8) {
                ForEach(0..<totalPages, id: \.self) { index in
                    Capsule()
                        .fill(index == currentPage ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: index == currentPage ? 24 : 8, height: 8)
                        .animation(.spring(response: 0.3), value: currentPage)
                }
            }
            .padding(.top, 20)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Page \(currentPage + 1) of \(totalPages)")
            #endif

            TabView(selection: $currentPage) {
                // Page 1: Welcome
                welcomePage
                    .tag(0)

                // Page 2: Track Time
                trackTimePage
                    .tag(1)

                // Page 3: Focus Mode
                focusModePage
                    .tag(2)
            }
            #if os(iOS)
            .tabViewStyle(.page(indexDisplayMode: .never))
            #else
            .tabViewStyle(.automatic)
            #endif
        }
        .interactiveDismissDisabled()
    }

    // MARK: - Page 1: Welcome

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()

            // App Icon
            if let appIcon = PlatformImage(named: "AppIcon") ?? Bundle.main.icon {
                #if canImport(UIKit)
                Image(uiImage: appIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .shadow(color: Color.black.opacity(0.2), radius: 20, y: 10)
                #else
                Image(nsImage: appIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .shadow(color: Color.black.opacity(0.2), radius: 20, y: 10)
                #endif
            }

            VStack(spacing: 12) {
                Text("Welcome to DevHours")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Track your time, stay focused, and get more done.")
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

    // MARK: - Page 2: Track Time

    private var trackTimePage: some View {
        VStack(spacing: 24) {
            Spacer()

            featureShowcase(
                icon: "timer",
                iconColor: .blue,
                title: "Effortless Time Tracking",
                features: [
                    FeatureItem(icon: "play.circle.fill", text: "One-tap timer to start tracking"),
                    FeatureItem(icon: "folder.fill", text: "Organize by clients & projects"),
                    FeatureItem(icon: "chart.bar.fill", text: "See where your time goes")
                ]
            )

            Spacer()

            Button {
                withAnimation {
                    currentPage = 2
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

    // MARK: - Page 3: Focus Mode

    private var focusModePage: some View {
        VStack(spacing: 24) {
            Spacer()

            featureShowcase(
                icon: "brain.head.profile",
                iconColor: .purple,
                title: "Stay in the Zone",
                features: [
                    FeatureItem(icon: "moon.fill", text: "Block distracting apps while you work"),
                    FeatureItem(icon: "shield.fill", text: "Gentle reminders if you stray"),
                    FeatureItem(icon: "flame.fill", text: "Build focus streaks")
                ]
            )

            Spacer()

            Button {
                completeOnboarding()
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Page 4: Get Started

    private var getStartedPage: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60, weight: .medium))
                    .foregroundStyle(.green)
            }

            VStack(spacing: 12) {
                Text("You're Ready!")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Start your first timer and take control of your time.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    completeOnboarding()
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)

                Text("You can set up Focus Mode later in Settings")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Feature Showcase

    private func featureShowcase(
        icon: String,
        iconColor: Color,
        title: String,
        features: [FeatureItem]
    ) -> some View {
        VStack(spacing: 32) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: icon)
                    .font(.system(size: 44, weight: .medium))
                    .foregroundStyle(iconColor)
            }

            Text(title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 16) {
                ForEach(features, id: \.text) { feature in
                    HStack(spacing: 16) {
                        Image(systemName: feature.icon)
                            .font(.title3)
                            .foregroundStyle(iconColor)
                            .frame(width: 28)

                        Text(feature.text)
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                }
            }
            .padding(.horizontal, 40)
        }
    }

    // MARK: - Actions

    private func completeOnboarding() {
        Self.hasCompletedOnboarding = true
        onComplete()
        dismiss()
    }
}

// MARK: - Feature Item

private struct FeatureItem {
    let icon: String
    let text: String
}

// MARK: - Bundle Extension

#if canImport(UIKit)
private extension Bundle {
    var icon: UIImage? {
        if let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
           let lastIcon = iconFiles.last {
            return UIImage(named: lastIcon)
        }
        return nil
    }
}
#elseif canImport(AppKit)
private extension Bundle {
    var icon: NSImage? {
        NSApplication.shared.applicationIconImage
    }
}
#endif

#Preview {
    AppOnboardingView(onComplete: {})
}
