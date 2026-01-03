//
//  EntryEditSheet.swift
//  DevHours
//
//  Created on 12/14/24.
//

import SwiftUI
import SwiftData

struct EntryEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var entry: TimeEntry

    // Query all clients and projects for pickers (iOS only)
    #if os(iOS)
    @Query(sort: \Client.name) private var allClients: [Client]
    @Query(sort: \Project.name) private var allProjects: [Project]
    #endif

    // Query all tags for picker
    @Query(sort: \Tag.name) private var allTags: [Tag]

    // Track running state separately for UI
    @State private var isRunning: Bool
    @State private var showDeleteConfirmation = false
    @State private var showValidationError = false

    // Temporary end time for editing (if not running)
    @State private var tempEndTime: Date

    let onDelete: () -> Void

    init(entry: TimeEntry, onDelete: @escaping () -> Void) {
        self.entry = entry
        self.onDelete = onDelete

        // Initialize state from entry
        _isRunning = State(initialValue: entry.endTime == nil)
        _tempEndTime = State(initialValue: entry.endTime ?? Date.now)
    }

    // Projects filtered by selected client (iOS only)
    #if os(iOS)
    private var filteredProjects: [Project] {
        if let client = entry.client {
            return allProjects.filter { $0.client?.id == client.id }
        } else {
            return allProjects
        }
    }
    #endif

    var body: some View {
        NavigationStack {
            Form {
                // Title Section
                Section("Title") {
                    TextField("Entry title", text: $entry.title)
                }

                // Time Section
                Section("Time") {
                    DatePicker(
                        "Start",
                        selection: $entry.startTime,
                        displayedComponents: [.date, .hourAndMinute]
                    )

                    Toggle("Running", isOn: $isRunning)
                        .onChange(of: isRunning) { _, newValue in
                            if newValue {
                                // Set to running
                                entry.endTime = nil
                            } else {
                                // Set to stopped (use current time or last known end time)
                                entry.endTime = tempEndTime
                            }
                        }

                    if !isRunning {
                        DatePicker(
                            "End",
                            selection: Binding(
                                get: { entry.endTime ?? tempEndTime },
                                set: { newValue in
                                    tempEndTime = newValue
                                    entry.endTime = newValue
                                }
                            ),
                            displayedComponents: [.date, .hourAndMinute]
                        )

                        // Duration display
                        HStack {
                            Text("Duration")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(DurationFormatter.formatHoursMinutes(entry.duration))
                                .foregroundStyle(.primary)
                        }
                    } else {
                        HStack {
                            Text("Duration")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(DurationFormatter.formatHoursMinutes(entry.duration))
                                .foregroundStyle(.primary)
                            Image(systemName: "circle.fill")
                                .font(.caption2)
                                .foregroundStyle(.green)
                        }
                    }
                }

                // Client & Project Section (iOS only - pickers cause issues on macOS)
                #if os(iOS)
                Section("Organization") {
                    Picker("Client", selection: $entry.client) {
                        Text("None").tag(nil as Client?)
                        ForEach(allClients) { client in
                            Text(client.name).tag(client as Client?)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: entry.client) { oldValue, newValue in
                        // Clear project if client changed and project doesn't belong to new client
                        if let project = entry.project,
                           project.client?.id != newValue?.id {
                            entry.project = nil
                        }
                    }

                    Picker("Project", selection: $entry.project) {
                        Text("None").tag(nil as Project?)
                        ForEach(filteredProjects) { project in
                            Text(project.name).tag(project as Project?)
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(entry.client == nil)

                    if entry.client == nil {
                        Text("Select a client to choose a project")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                #endif

                // Tags Section
                Section {
                    if allTags.isEmpty {
                        HStack {
                            Text("No tags available")
                                .foregroundStyle(.secondary)
                            Spacer()
                            NavigationLink {
                                TagsListView()
                            } label: {
                                Text("Create")
                                    .font(.subheadline)
                            }
                        }
                    } else {
                        TagMultiSelectView(allTags: allTags, selectedTags: $entry.tags)
                    }
                } header: {
                    Text("Tags")
                }

                // Delete Section
                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Delete Entry")
                            Spacer()
                        }
                    }
                }
            }
            #if os(macOS)
            .formStyle(.grouped)
            .frame(minWidth: 400, idealWidth: 450, maxWidth: 500)
            .frame(minHeight: 400)
            #endif
            .navigationTitle("Edit Entry")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEntry()
                    }
                }
            }
            .alert("Delete Entry?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    onDelete()
                    dismiss()
                }
            } message: {
                Text("This action cannot be undone.")
            }
            .alert("Invalid Time Range", isPresented: $showValidationError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("End time must be after start time.")
            }
        }
    }

    private func saveEntry() {
        // Validate: if not running, endTime must be > startTime
        if !isRunning {
            guard let endTime = entry.endTime, endTime > entry.startTime else {
                showValidationError = true
                return
            }
        }

        // Save changes (already bound to entry via @Bindable)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving entry: \(error)")
            // Could show error alert here
        }
    }
}
