//
//  EntriesView.swift
//  DevHours
//
//  Created on 12/14/24.
//

import SwiftUI
import SwiftData

struct EntriesView: View {
    @Environment(\.modelContext) private var modelContext

    // Query all entries sorted by start time (newest first)
    @Query(sort: \TimeEntry.startTime, order: .reverse)
    private var allEntries: [TimeEntry]

    // Search state
    @State private var searchText = ""

    // Edit sheet state
    @State private var selectedEntry: TimeEntry?
    @State private var showEditSheet = false

    // Filtered entries based on search
    private var filteredEntries: [TimeEntry] {
        var results = allEntries
        if !searchText.isEmpty {
            results = results.filter { entry in
                entry.title.localizedCaseInsensitiveContains(searchText) ||
                entry.client?.name.localizedCaseInsensitiveContains(searchText) == true ||
                entry.project?.name.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        return results
    }

    // Summary computed properties
    private var totalDuration: TimeInterval {
        filteredEntries.reduce(0) { $0 + $1.duration }
    }

    private var entryCount: Int {
        filteredEntries.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Summary Header (only show if there are entries)
                    if !filteredEntries.isEmpty {
                        EntriesSummaryHeader(
                            totalDuration: totalDuration,
                            entryCount: entryCount
                        )
                        .padding(.horizontal, 16)
                    }

                    // Entry List
                    if filteredEntries.isEmpty {
                        // Empty state placeholder for now
                        VStack(spacing: 16) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 48))
                                .foregroundStyle(.tertiary)

                            VStack(spacing: 4) {
                                Text(allEntries.isEmpty ? "No time entries yet" : "No matching entries")
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                Text(allEntries.isEmpty ? "Start tracking in the Today tab" : "Try adjusting your search")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredEntries) { entry in
                                EntryRow(entry: entry)
                                    .padding(.horizontal, 16)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedEntry = entry
                                        showEditSheet = true
                                    }
                            }
                        }
                    }
                }
                .padding(.top, 8)
            }
            .background(Color(.secondarySystemBackground))
            .navigationTitle("Entries")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search entries")
            .sheet(isPresented: $showEditSheet) {
                if let entry = selectedEntry {
                    EntryEditSheet(entry: entry, onDelete: {
                        deleteEntry(entry)
                    })
                }
            }
        }
    }

    private func deleteEntry(_ entry: TimeEntry) {
        modelContext.delete(entry)
        do {
            try modelContext.save()
        } catch {
            print("Error deleting entry: \(error)")
        }
        showEditSheet = false
        selectedEntry = nil
    }
}
