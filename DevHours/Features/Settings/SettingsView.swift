//
//  SettingsView.swift
//  DevHours
//
//  Created on 12/26/24.
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

struct SettingsView: View {
    @Environment(FocusBlockingService.self) private var focusService
    @Environment(PremiumManager.self) private var premiumManager

    @State private var showingOnboarding = false

    var body: some View {
        NavigationStack {
            List {
                Section("Organization") {
                    NavigationLink {
                        ProjectsListView()
                    } label: {
                        Label("Manage Projects", systemImage: "folder")
                    }

                    NavigationLink {
                        TagsListView()
                    } label: {
                        Label("Manage Tags", systemImage: "tag")
                    }
                }

                // Focus Mode Section
                Section {
                    if focusService.isAuthorized {
                        NavigationLink {
                            FocusProfilesView()
                        } label: {
                            Label("Focus Profiles", systemImage: "moon.fill")
                        }

                        NavigationLink {
                            FocusStatsView()
                        } label: {
                            HStack {
                                Label("Focus Statistics", systemImage: "chart.bar.fill")
                                Spacer()
                                if !premiumManager.isPremium {
                                    Text("PRO")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.orange)
                                        .clipShape(Capsule())
                                }
                            }
                        }

                        // Default strictness picker
                        Picker(selection: .constant(StrictnessLevel.firm)) {
                            ForEach(StrictnessLevel.allCases, id: \.self) { level in
                                Text(level.displayName).tag(level)
                            }
                        } label: {
                            Label("Default Strictness", systemImage: "lock.fill")
                        }
                    } else {
                        Button {
                            showingOnboarding = true
                        } label: {
                            HStack {
                                Label("Set Up Focus Mode", systemImage: "moon.fill")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                } header: {
                    Text("Focus Mode")
                } footer: {
                    if !focusService.isAuthorized {
                        Text("Block distracting apps while you work. Requires Screen Time permission.")
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    // Feedback button
                    Button {
                        sendFeedback()
                    } label: {
                        HStack {
                            Label("Send Feedback", systemImage: "envelope")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                #if DEBUG
                Section {
                    Toggle(isOn: Binding(
                        get: { premiumManager.isPremium },
                        set: { premiumManager.isPremium = $0 }
                    )) {
                        Label("Premium Mode", systemImage: "star.fill")
                    }
                    .tint(.orange)
                } header: {
                    Text("Debug")
                } footer: {
                    Text("Toggle to test premium features. This only appears in debug builds.")
                }
                #endif
            }
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .sheet(isPresented: $showingOnboarding) {
                FocusOnboardingView {
                    // Onboarding complete
                }
            }
        }
    }

    private func sendFeedback() {
        #if os(iOS)
        let email = "3tobiasfu@gmail.com"
        let subject = "Liquid Time Feedback"
        let body = "\n\n---\nLiquid Time v1.0.0"

        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        if let url = URL(string: "mailto:\(email)?subject=\(encodedSubject)&body=\(encodedBody)") {
            UIApplication.shared.open(url)
        }
        #endif
    }
}

#Preview {
    SettingsView()
}
