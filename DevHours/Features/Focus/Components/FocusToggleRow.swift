//
//  FocusToggleRow.swift
//  DevHours
//
//  Toggle row for enabling Focus Mode on the timer card.
//

import SwiftUI
import SwiftData

struct FocusToggleRow: View {
    @Environment(FocusBlockingService.self) private var focusService
    @Environment(PremiumManager.self) private var premiumManager

    @Binding var isEnabled: Bool
    @Binding var selectedProfile: FocusProfile?

    @Query(sort: \FocusProfile.sortOrder) private var profiles: [FocusProfile]

    @State private var showingProfilePicker = false
    @State private var showingOnboarding = false
    @State private var showingPremiumPrompt = false

    var body: some View {
        HStack(spacing: 12) {
            // Focus Mode label and profile selector
            Button {
                if focusService.isAuthorized {
                    showingProfilePicker = true
                } else {
                    showingOnboarding = true
                }
            } label: {
                HStack(spacing: 8) {
//                    Image(systemName: "moon.fill")
//                        .font(.subheadline)
//                        .foregroundStyle(isEnabled ? Color.accentColor : .secondary)

                    if let profile = selectedProfile {
                        HStack(spacing: 4) {
                            Image(systemName: profile.iconName)
                                .font(.caption)
                            Text(profile.name)
                                .font(.subheadline)
                        }
                        .foregroundStyle(isEnabled ? Color.fromHex(profile.colorHex) : .secondary)
                    } else {
                        Text("Focus Mode")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isEnabled ? Color.accentColor.opacity(0.1) : Color.secondary.opacity(0.1))
                )
            }
            .buttonStyle(.plain)

            Spacer()

            // Toggle
            Toggle("", isOn: $isEnabled)
                .labelsHidden()
                .tint(Color.accentColor)
                .onChange(of: isEnabled) { _, newValue in
                    handleToggleChange(newValue)
                }
        }
        .padding(.horizontal, 4)
        .sheet(isPresented: $showingOnboarding) {
            FocusOnboardingView {
                // After onboarding, select first profile
                if let firstProfile = profiles.first {
                    selectedProfile = firstProfile
                    isEnabled = true
                }
            }
        }
        .sheet(isPresented: $showingProfilePicker) {
            NavigationStack {
                FocusProfilePickerView(selectedProfile: $selectedProfile)
            }
            .presentationDetents([.medium])
        }
        .alert("Premium Feature", isPresented: $showingPremiumPrompt) {
            Button("Maybe Later", role: .cancel) {}
            Button("Learn More") {
                // TODO: Show paywall
            }
        } message: {
            Text(premiumManager.sessionLimitMessage)
        }
        .onAppear {
            // Select default profile if none selected
            if selectedProfile == nil, let defaultProfile = profiles.first(where: { $0.isDefault }) {
                selectedProfile = defaultProfile
            }
        }
    }

    private func handleToggleChange(_ enabled: Bool) {
        if enabled {
            // Check authorization
            if !focusService.isAuthorized {
                isEnabled = false
                showingOnboarding = true
                return
            }

            // Check premium limits
            if !premiumManager.canStartFocusSession() {
                isEnabled = false
                showingPremiumPrompt = true
                return
            }

            // Ensure we have a profile selected
            if selectedProfile == nil {
                if let defaultProfile = profiles.first(where: { $0.isDefault }) ?? profiles.first {
                    selectedProfile = defaultProfile
                } else {
                    isEnabled = false
                    return
                }
            }
        }
    }
}

// MARK: - Profile Picker View

struct FocusProfilePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedProfile: FocusProfile?

    @Query(sort: \FocusProfile.sortOrder) private var profiles: [FocusProfile]

    var body: some View {
        List {
            ForEach(profiles) { profile in
                ProfilePickerRow(
                    profile: profile,
                    isSelected: selectedProfile?.id == profile.id,
                    onSelect: {
                        selectedProfile = profile
                        dismiss()
                    }
                )
            }
        }
        .navigationTitle("Select Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Profile Picker Row

private struct ProfilePickerRow: View {
    let profile: FocusProfile
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                profileIcon
                profileInfo
                Spacer()
                selectionIndicator
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var profileIcon: some View {
        let color = Color.fromHex(profile.colorHex)
        return ZStack {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 40, height: 40)
            Image(systemName: profile.iconName)
                .foregroundStyle(color)
        }
    }

    private var profileInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(profile.name)
                .font(.headline)
                .foregroundStyle(.primary)
            Text(profile.strictnessLevel.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var selectionIndicator: some View {
        if isSelected {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.accentColor)
        }
    }
}

#Preview {
    FocusToggleRow(
        isEnabled: .constant(false),
        selectedProfile: .constant(nil)
    )
    .padding()
}
