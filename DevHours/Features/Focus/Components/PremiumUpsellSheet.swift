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
        title: String = "Premium",
        subtitle: String = "One-time purchase, lifetime access",
        highlightedFeature: PremiumFeature? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.highlightedFeature = highlightedFeature
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        headerSection

                        // Feature List
                        featureListSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }

                // Fixed bottom CTA
                ctaSection
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
                            .foregroundStyle(.tertiary)
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
        VStack(spacing: 12) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    // MARK: - Feature List Section

    private var featureListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(displayedFeatures, id: \.self) { feature in
                FeatureRow(
                    feature: feature,
                    isHighlighted: feature == highlightedFeature
                )
            }
        }
    }

    private var displayedFeatures: [PremiumFeature] {
        // Show highlighted feature first if present
        var features = PremiumFeature.allCases.filter { $0 != .scheduledFocus }
        if let highlighted = highlightedFeature,
           let index = features.firstIndex(of: highlighted) {
            features.remove(at: index)
            features.insert(highlighted, at: 0)
        }
        return features
    }

    // MARK: - CTA Section

    private var ctaSection: some View {
        VStack(spacing: 12) {
            // Purchase button with price
            Button {
                Task {
                    await purchaseLifetime()
                }
            } label: {
                HStack(spacing: 8) {
                    if isPurchasing || premiumManager.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Upgrade")
                        Text("·")
                            .foregroundStyle(.white.opacity(0.5))
                        Text(premiumManager.priceString)
                    }
                }
                .font(.body.weight(.medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isPurchasing || premiumManager.isLoading)

            // Restore purchases
            Button {
                Task {
                    await restorePurchases()
                }
            } label: {
                Text("Restore Purchase")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .disabled(isPurchasing || premiumManager.isLoading)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .background(.bar)
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
        HStack(spacing: 12) {
            Image(systemName: feature.iconName)
                .font(.body)
                .foregroundStyle(isHighlighted ? Color.accentColor : .secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(feature.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(isHighlighted ? .primary : .primary)

                Text(feature.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Convenience Initializers

extension PremiumUpsellSheet {
    /// Creates an upsell sheet for the session limit
    static var sessionLimit: PremiumUpsellSheet {
        PremiumUpsellSheet(
            title: "Weekly Limit Reached",
            subtitle: "Free plan includes 3 sessions per week",
            highlightedFeature: .unlimitedSessions
        )
    }

    /// Creates an upsell sheet for profile creation
    static var profileLimit: PremiumUpsellSheet {
        PremiumUpsellSheet(
            title: "Custom Profiles",
            subtitle: "Create profiles for different contexts",
            highlightedFeature: .customProfiles
        )
    }

    /// Creates an upsell sheet for strictness levels
    static var strictnessLevels: PremiumUpsellSheet {
        PremiumUpsellSheet(
            title: "Strictness Levels",
            subtitle: "Control how apps are blocked",
            highlightedFeature: .allStrictnessLevels
        )
    }

    /// Creates an upsell sheet for stats access
    static var focusStats: PremiumUpsellSheet {
        PremiumUpsellSheet(
            title: "Focus Stats",
            subtitle: "View your focus history and trends",
            highlightedFeature: .focusStats
        )
    }
}

#Preview {
    PremiumUpsellSheet()
}

#Preview("Session Limit") {
    PremiumUpsellSheet.sessionLimit
}
