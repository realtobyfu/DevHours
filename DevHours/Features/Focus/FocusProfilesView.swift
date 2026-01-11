//
//  FocusProfilesView.swift
//  DevHours
//
//  List of focus profiles with management options.
//

import SwiftUI
import SwiftData

struct FocusProfilesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(PremiumManager.self) private var premiumManager

    @Query(sort: \FocusProfile.sortOrder) private var profiles: [FocusProfile]

    @State private var showingNewProfile = false
    @State private var profileToEdit: FocusProfile?
    @State private var showingPremiumPrompt = false
    @State private var showingPaywall = false

    var body: some View {
        List {
            Section {
                ForEach(profiles) { profile in
                    FocusProfileRow(profile: profile)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            profileToEdit = profile
                        }
                }
                .onDelete(perform: deleteProfiles)
            } footer: {
                if !premiumManager.isPremium {
                    Text("Free users can use the default Deep Work profile. Upgrade for custom profiles.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Focus Profiles")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    if premiumManager.canCreateProfile() {
                        showingNewProfile = true
                    } else {
                        showingPremiumPrompt = true
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewProfile) {
            NavigationStack {
                FocusProfileEditView(profile: nil)
            }
        }
        .sheet(item: $profileToEdit) { profile in
            NavigationStack {
                FocusProfileEditView(profile: profile)
            }
        }
        .alert("Premium Feature", isPresented: $showingPremiumPrompt) {
            Button("Maybe Later", role: .cancel) {}
            Button("Upgrade") {
                showingPaywall = true
            }
        } message: {
            Text(premiumManager.profileLimitMessage)
        }
        .sheet(isPresented: $showingPaywall) {
            PremiumUpsellSheet.profileLimit
        }
    }

    private func deleteProfiles(at offsets: IndexSet) {
        for index in offsets {
            let profile = profiles[index]
            // Don't allow deleting default profiles if it would leave none
            if profile.isDefault && profiles.filter({ $0.isDefault }).count <= 1 {
                continue
            }
            modelContext.delete(profile)
        }
        try? modelContext.save()
    }
}

// MARK: - Profile Row

struct FocusProfileRow: View {
    let profile: FocusProfile

    var body: some View {
        HStack(spacing: 12) {
            // Profile icon
            ZStack {
                Circle()
                    .fill(Color.fromHex(profile.colorHex).opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: profile.iconName)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(Color.fromHex(profile.colorHex))
            }

            // Profile info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(profile.name)
                        .font(.headline)

                    if profile.isDefault {
                        Text("DEFAULT")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: 8) {

                    if profile.hasBlockedApps {
                        Text("Apps selected")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("No apps selected")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        FocusProfilesView()
    }
}
