//
//  PremiumUpsellSheet.swift
//  DevHours
//
//  Reusable premium upsell sheet with feature comparison.
//

import SwiftUI

struct PremiumUpsellSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PremiumManager.self) private var premiumManager

    let title: String
    let subtitle: String
    let highlightedFeature: PremiumFeature?

    @State private var isPurchasing = false
    @State private var showingError = false
    @State private var errorMessage = ""

    init(
        title: String = "Unlock Premium",
        subtitle: String = "Get the most out of your focus time",
        highlightedFeature: PremiumFeature? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.highlightedFeature = highlightedFeature
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Feature List
                    featureListSection

                    // CTA Button
                    ctaSection
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
            .navigationTitle("")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .alert("Purchase Failed", isPresented: $showingError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onChange(of: premiumManager.isPremium) { _, isPremium in
            if isPremium {
                dismiss()
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "sparkles")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 8) {
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 16)
    }

    // MARK: - Feature List Section

    private var featureListSection: some View {
        VStack(spacing: 0) {
            ForEach(displayedFeatures, id: \.self) { feature in
                FeatureRow(
                    feature: feature,
                    isHighlighted: feature == highlightedFeature
                )

                if feature != displayedFeatures.last {
                    Divider()
                        .padding(.leading, 52)
                }
            }
        }
        #if os(iOS)
        .background(Color(.secondarySystemBackground))
        #else
        .background(Color.secondary.opacity(0.08))
        #endif
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var displayedFeatures: [PremiumFeature] {
        // Show highlighted feature first if present
        var features = PremiumFeature.allCases.filter { $0 != .scheduledFocus } // Hide future features
        if let highlighted = highlightedFeature,
           let index = features.firstIndex(of: highlighted) {
            features.remove(at: index)
            features.insert(highlighted, at: 0)
        }
        return features
    }

    // MARK: - CTA Section

    private var ctaSection: some View {
        VStack(spacing: 16) {
            // Price display
            VStack(spacing: 4) {
                Text("One-Time Purchase")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(premiumManager.priceString)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text("Lifetime Access")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 8)

            // Purchase button
            Button {
                Task {
                    await purchaseLifetime()
                }
            } label: {
                HStack(spacing: 8) {
                    if isPurchasing || premiumManager.isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(isPurchasing ? "Processing..." : "Get Premium")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isPurchasing || premiumManager.isLoading)

            // Restore purchases
            Button {
                Task {
                    await restorePurchases()
                }
            } label: {
                Text("Restore Purchases")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .disabled(isPurchasing || premiumManager.isLoading)

            Text("Pay once, own forever. No subscriptions.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    // MARK: - Purchase Actions

    @MainActor
    private func purchaseLifetime() async {
        isPurchasing = true

        let success = await premiumManager.purchaseLifetime()

        isPurchasing = false

        if !success {
            if let error = premiumManager.purchaseError {
                errorMessage = error
                showingError = true
            }
        }
        // Success case: onChange(of: isPremium) will dismiss
    }

    @MainActor
    private func restorePurchases() async {
        isPurchasing = true
        await premiumManager.restorePurchases()
        isPurchasing = false

        if !premiumManager.isPremium {
            errorMessage = "No previous purchases found."
            showingError = true
        }
        // Success case: onChange(of: isPremium) will dismiss
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let feature: PremiumFeature
    let isHighlighted: Bool

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(isHighlighted ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
                    .frame(width: 36, height: 36)

                Image(systemName: feature.iconName)
                    .font(.body.weight(.medium))
                    .foregroundStyle(isHighlighted ? Color.accentColor : .secondary)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(feature.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if isHighlighted {
                        Text("NEW")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor)
                            .clipShape(Capsule())
                    }
                }

                Text(feature.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "checkmark")
                .font(.body.weight(.medium))
                .foregroundStyle(.green)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isHighlighted ? Color.accentColor.opacity(0.05) : Color.clear)
    }
}

// MARK: - Convenience Initializers

extension PremiumUpsellSheet {
    /// Creates an upsell sheet for the session limit
    static var sessionLimit: PremiumUpsellSheet {
        PremiumUpsellSheet(
            title: "Out of Free Sessions",
            subtitle: "You've used all 3 free focus sessions this week",
            highlightedFeature: .unlimitedSessions
        )
    }

    /// Creates an upsell sheet for profile creation
    static var profileLimit: PremiumUpsellSheet {
        PremiumUpsellSheet(
            title: "Create Custom Profiles",
            subtitle: "Build focus profiles for different contexts",
            highlightedFeature: .customProfiles
        )
    }

    /// Creates an upsell sheet for strictness levels
    static var strictnessLevels: PremiumUpsellSheet {
        PremiumUpsellSheet(
            title: "More Control",
            subtitle: "Choose how hard it is to unlock blocked apps",
            highlightedFeature: .allStrictnessLevels
        )
    }

    /// Creates an upsell sheet for stats access
    static var focusStats: PremiumUpsellSheet {
        PremiumUpsellSheet(
            title: "Track Your Progress",
            subtitle: "See detailed focus statistics and achievements",
            highlightedFeature: .focusStats
        )
    }
}

#Preview {
    PremiumUpsellSheet(
        title: "Unlock Premium",
        subtitle: "Get the most out of your focus time",
        highlightedFeature: .unlimitedSessions
    )
}
