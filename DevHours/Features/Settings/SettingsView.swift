//
//  SettingsView.swift
//  DevHours
//
//  Created on 12/26/24.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Organization") {
                    NavigationLink {
                        ProjectsListView()
                    } label: {
                        Label("Manage Projects", systemImage: "folder")
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
        }
    }
}

#Preview {
    SettingsView()
}
