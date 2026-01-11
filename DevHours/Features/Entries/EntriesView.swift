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

    // Group entries by date
    private var groupedEntries: [(date: Date, entries: [TimeEntry])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredEntries) { entry in
            calendar.startOfDay(for: entry.startTime)
        }
        return grouped.sorted { $0.key > $1.key }
            .map { (date: $0.key, entries: $0.value) }
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
            List {
                // Summary Header Section
                if !filteredEntries.isEmpty {
                    EntriesSummaryHeader(
                        totalDuration: totalDuration,
                        entryCount: entryCount
                    )
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                // Entry List grouped by date
                if filteredEntries.isEmpty {
                    emptyStateView
                } else {
                    ForEach(groupedEntries, id: \.date) { group in
                        Section {
                            ForEach(group.entries) { entry in
                                entryRowView(for: entry)
                            }
                        } header: {
                            DateSectionHeader(date: group.date, entryCount: group.entries.count)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.secondarySystemBackground)
            .navigationTitle("Entries")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
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

    // MARK: - Subviews

    private var emptyStateView: some View {
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
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    private func entryRowView(for entry: TimeEntry) -> some View {
        EntryRow(entry: entry)
            .contentShape(Rectangle())
            .onTapGesture {
                selectedEntry = entry
                showEditSheet = true
            }
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    deleteEntry(entry)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            .contextMenu {
                Button {
                    selectedEntry = entry
                    showEditSheet = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    deleteEntry(entry)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
    }

    // MARK: - Actions

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

// MARK: - Date Section Header

private struct DateSectionHeader: View {
    let date: Date
    let entryCount: Int

    var body: some View {
        HStack {
            Text(formatSectionDate(date))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            Spacer()

            Text("\(entryCount) \(entryCount == 1 ? "entry" : "entries")")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
//        .padding(.vertical, 4)
        .textCase(nil)
    }

    private func formatSectionDate(_ date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            // This week - show day name
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .year) {
            // This year - show month and day
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: date)
        } else {
            // Different year - show full date
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d, yyyy"
            return formatter.string(from: date)
        }
    }
}
