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
            }
            .navigationTitle("Settings")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
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
