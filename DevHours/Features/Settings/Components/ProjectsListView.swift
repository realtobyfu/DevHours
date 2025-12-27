//
//  ProjectsListView.swift
//  DevHours
//
//  Created on 12/26/24.
//

import SwiftUI
import SwiftData

struct ProjectsListView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Project.name)
    private var projects: [Project]

    @State private var showAddSheet = false
    @State private var selectedProject: Project?

    var body: some View {
        List {
            if projects.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 48))
                        .foregroundStyle(.tertiary)

                    VStack(spacing: 4) {
                        Text("No projects yet")
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text("Create a project to organize your time entries")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                ForEach(projects) { project in
                    ProjectRow(project: project)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedProject = project
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteProject(project)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
        .navigationTitle("Projects")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .accessibilityLabel("Add project")
            }
        }
        .sheet(isPresented: $showAddSheet) {
            ProjectEditSheet(project: nil)
        }
        .sheet(item: $selectedProject) { project in
            ProjectEditSheet(project: project)
        }
    }

    private func deleteProject(_ project: Project) {
        modelContext.delete(project)
        do {
            try modelContext.save()
        } catch {
            print("Error deleting project: \(error)")
        }
    }
}

struct ProjectRow: View {
    let project: Project

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(project.name)
                    .font(.headline)

                HStack(spacing: 8) {
                    if project.isBillable {
                        Label("Billable", systemImage: "dollarsign.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }

                    Text("\(project.timeEntries.count) entries")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        ProjectsListView()
            .modelContainer(for: Project.self, inMemory: true)
    }
}
