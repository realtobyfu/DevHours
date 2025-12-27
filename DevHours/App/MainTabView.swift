//
//  MainTabView.swift
//  DevHours
//
//  Created on 12/13/24.
//

import SwiftUI

enum NavigationItem: String, CaseIterable, Identifiable {
    case today = "Today"
    case entries = "Entries"
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .today: return "timer"
        case .entries: return "list.bullet"
        case .settings: return "gear"
        }
    }
}

struct MainTabView: View {
    #if os(macOS)
    @State private var selection: NavigationItem? = .today

    var body: some View {
        NavigationSplitView {
            List(NavigationItem.allCases, selection: $selection) { item in
                Label(item.rawValue, systemImage: item.icon)
                    .tag(item)
            }
            .navigationTitle("DevHours")
        } detail: {
            switch selection {
            case .today:
                TodayView()
            case .entries:
                EntriesView()
            case .settings:
                Text("Settings (Coming Soon)")
            case nil:
                Text("Select an item")
                    .foregroundStyle(.secondary)
            }
        }
    }
    #else
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

            Text("Settings (Coming Soon)")
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
    #endif
}


#Preview {
    MainTabView()
}

