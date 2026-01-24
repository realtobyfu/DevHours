//
//  FocusProfileEditView.swift
//  DevHours
//
//  Create or edit a focus profile with app selection.
//

import SwiftUI
import SwiftData
#if !os(macOS)
import FamilyControls
#endif

#if !os(macOS)
struct FocusProfileEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(PremiumManager.self) private var premiumManager

    let profile: FocusProfile?

    @State private var name: String = ""
    @State private var iconName: String = "brain.head.profile"
    @State private var colorHex: String = "#5E35B1"
    @State private var strictnessLevel: StrictnessLevel = .firm
    @State private var customMessage: String = ""
    @State private var appSelection = FamilyActivitySelection()
    @State private var showingAppPicker = false

    private var isNewProfile: Bool { profile == nil }

    private let iconOptions = [
        "brain.head.profile",
        "book.fill",
        "moon.fill",
        "laptopcomputer",
        "pencil",
        "paintbrush.fill",
        "music.note",
        "figure.run",
        "heart.fill",
        "star.fill"
    ]

    private let colorOptions = [
        "#5E35B1",  // Indigo
        "#00897B",  // Teal
        "#8E24AA",  // Purple
        "#E53935",  // Red
        "#FB8C00",  // Orange
        "#43A047",  // Green
        "#1E88E5",  // Blue
        "#6D4C41",  // Brown
    ]

    var body: some View {
        Form {
            // Basic Info Section
            Section("Profile Info") {
                TextField("Name", text: $name)
                    .textInputAutocapitalization(.words)

                // Icon picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Icon")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(iconOptions, id: \.self) { icon in
                                Button {
                                    iconName = icon
                                } label: {
                                    Image(systemName: icon)
                                        .font(.title2)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            iconName == icon
                                            ? Color.fromHex(colorHex).opacity(0.2)
                                            : Color.secondary.opacity(0.1)
                                        )
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .strokeBorder(
                                                    iconName == icon ? Color.fromHex(colorHex) : Color.clear,
                                                    lineWidth: 2
                                                )
                                        )
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(iconName == icon ? Color.fromHex(colorHex) : .secondary)
                            }
                        }
                    }
                }

                // Color picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Color")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        ForEach(colorOptions, id: \.self) { color in
                            Button {
                                colorHex = color
                            } label: {
                                Circle()
                                    .fill(Color.fromHex(color))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(Color.primary, lineWidth: colorHex == color ? 2 : 0)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            // App Selection Section
            Section {
                Button {
                    showingAppPicker = true
                } label: {
                    HStack {
                        Label("Select Apps to Block", systemImage: "apps.iphone")

                        Spacer()

                        if !appSelection.applicationTokens.isEmpty || !appSelection.categoryTokens.isEmpty {
                            Text(selectionSummary)
                                .foregroundStyle(.secondary)
                        }

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
            } header: {
                Text("Blocked Apps")
            } footer: {
                Text("Choose which apps and categories to block during focus sessions with this profile.")
            }

            // Strictness Section
            Section {
                Picker("Strictness", selection: $strictnessLevel) {
                    ForEach(StrictnessLevel.allCases, id: \.self) { level in
                        VStack(alignment: .leading) {
                            Text(level.displayName)
                        }
                        .tag(level)
                    }
                }

                // Strictness description
                HStack {
                    Image(systemName: strictnessIcon)
                        .foregroundStyle(strictnessColor)

                    Text(strictnessLevel.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Override Behavior")
            } footer: {
                Text("This controls how easy it is to unlock blocked apps during a session.")
            }

            // Custom Message Section
            if premiumManager.isPremium {
                Section {
                    TextField("Custom shield message", text: $customMessage, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("Shield Message")
                } footer: {
                    Text("This message appears when you try to open a blocked app.")
                }
            }

            // Delete Section
            if !isNewProfile && !(profile?.isDefault ?? false) {
                Section {
                    Button(role: .destructive) {
                        deleteProfile()
                    } label: {
                        Label("Delete Profile", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle(isNewProfile ? "New Profile" : "Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveProfile()
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .familyActivityPicker(
            isPresented: $showingAppPicker,
            selection: $appSelection
        )
        .onAppear {
            loadProfile()
        }
    }

    // MARK: - Computed Properties

    /// Generates a summary of selected apps and categories
    private var selectionSummary: String {
        let appCount = appSelection.applicationTokens.count
        let categoryCount = appSelection.categoryTokens.count

        if appCount > 0 && categoryCount > 0 {
            let appText = appCount == 1 ? "1 app" : "\(appCount) apps"
            let categoryText = categoryCount == 1 ? "1 category" : "\(categoryCount) categories"
            return "\(appText), \(categoryText)"
        } else if appCount > 0 {
            return appCount == 1 ? "1 app" : "\(appCount) apps"
        } else if categoryCount > 0 {
            return categoryCount == 1 ? "1 category" : "\(categoryCount) categories"
        }
        return ""
    }

    private var strictnessIcon: String {
        switch strictnessLevel {
        case .gentle: return "hand.tap"
        case .firm: return "hand.raised.fill"
        case .locked: return "lock.fill"
        }
    }

    private var strictnessColor: Color {
        switch strictnessLevel {
        case .gentle: return .green
        case .firm: return .orange
        case .locked: return .red
        }
    }

    // MARK: - Actions

    private func loadProfile() {
        guard let profile else { return }
        name = profile.name
        iconName = profile.iconName
        colorHex = profile.colorHex
        strictnessLevel = profile.strictnessLevel
        customMessage = profile.customShieldMessage ?? ""
        if let selection = profile.blockedApps {
            appSelection = selection
        }
    }

    private func saveProfile() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        if let existingProfile = profile {
            // Update existing
            existingProfile.name = trimmedName
            existingProfile.iconName = iconName
            existingProfile.colorHex = colorHex
            existingProfile.strictnessLevel = strictnessLevel
            existingProfile.customShieldMessage = customMessage.isEmpty ? nil : customMessage
            existingProfile.blockedApps = appSelection
        } else {
            // Create new
            let newProfile = FocusProfile(
                name: trimmedName,
                iconName: iconName,
                colorHex: colorHex,
                strictnessLevel: strictnessLevel,
                customShieldMessage: customMessage.isEmpty ? nil : customMessage,
                isDefault: false,
                sortOrder: 100  // Put custom profiles after defaults
            )
            newProfile.blockedApps = appSelection
            modelContext.insert(newProfile)
        }

        try? modelContext.save()
        dismiss()
    }

    private func deleteProfile() {
        guard let profile else { return }
        modelContext.delete(profile)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        FocusProfileEditView(profile: nil)
    }
}
#else
struct FocusProfileEditView: View {
    let profile: FocusProfile?

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "iphone")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)

            Text("Focus Mode is available on iPhone and iPad.")
                .font(.headline)
                .multilineTextAlignment(.center)

            Text("Create and manage focus profiles on iOS, then sync them to your Mac.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    FocusProfileEditView(profile: nil)
}
#endif
