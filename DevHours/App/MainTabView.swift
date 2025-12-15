//
//  MainTabView.swift
//  DevHours
//
//  Created on 12/13/24.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "timer")
                }

            EntriesView()
                .tabItem {
                    Label("Entries", systemImage: "list.bullet")
                }

            Text("Projects (Coming Soon)")
                .tabItem {
                    Label("Projects", systemImage: "folder")
                }

            Text("Reports (Coming Soon)")
                .tabItem {
                    Label("Reports", systemImage: "chart.bar")
                }

            Text("Settings (Coming Soon)")
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}


#Preview {
    MainTabView()
}

