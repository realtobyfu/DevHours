//
//  MainTabView.swift
//  DevHours
//
//  Created on 12/13/24.
//

import SwiftUI

enum NavigationItem: String, CaseIterable, Identifiable {
    case today = "Today"
    case planning = "Planning"
    case entries = "Entries"
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .today: return "timer"
        case .planning: return "calendar"
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
            .navigationTitle("Clockwise")
        } detail: {
            switch selection {
            case .today:
                TodayView()
            case .planning:
                PlanningView()
            case .entries:
                EntriesView()
            case .settings:
                SettingsView()
            case nil:
                Text("Select an item")
                    .foregroundStyle(.secondary)
            }
        }
    }
    #else
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selection: NavigationItem? = .today

    var body: some View {
        if horizontalSizeClass == .regular {
            NavigationSplitView {
                List(NavigationItem.allCases, selection: $selection) { item in
                    Label(item.rawValue, systemImage: item.icon)
                        .tag(item)
                }
                .navigationTitle("Clockwise")
            } detail: {
                switch selection {
                case .today:
                    TodayView()
                case .planning:
                    PlanningView()
                case .entries:
                    EntriesView()
                case .settings:
                    SettingsView()
                case nil:
                    Text("Select an item")
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            TabView {
                TodayView()
                    .tabItem {
                        Label("Today", systemImage: "timer")
                    }

                PlanningView()
                    .tabItem {
                        Label("Planning", systemImage: "calendar")
                    }

                EntriesView()
                    .tabItem {
                        Label("Entries", systemImage: "list.bullet")
                    }

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
            }
        }
    }
    #endif
}


#Preview {
    MainTabView()
}
