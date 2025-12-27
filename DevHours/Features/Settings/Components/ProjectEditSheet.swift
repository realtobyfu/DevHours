//
//  ProjectEditSheet.swift
//  DevHours
//
//  Created on 12/26/24.
//

import SwiftUI
import SwiftData

struct ProjectEditSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let project: Project?

    @State private var name: String = ""
    @State private var isBillable: Bool = true

    private var isEditing: Bool {
        project != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Project name", text: $name)
                } header: {
                    Text("Name")
                }

                Section {
                    Toggle("Billable", isOn: $isBillable)
                } header: {
                    Text("Settings")
                } footer: {
                    Text("Billable projects can be used for invoicing and reports.")
                }
            }
            .navigationTitle(isEditing ? "Edit Project" : "New Project")
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
                        save()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let project = project {
                    name = project.name
                    isBillable = project.isBillable
                }
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)

        if let project = project {
            // Update existing
            project.name = trimmedName
            project.isBillable = isBillable
        } else {
            // Create new
            let newProject = Project(name: trimmedName, isBillable: isBillable)
            modelContext.insert(newProject)
        }

        do {
            try modelContext.save()
        } catch {
            print("Error saving project: \(error)")
        }

        dismiss()
    }
}

#Preview("New Project") {
    ProjectEditSheet(project: nil)
        .modelContainer(for: Project.self, inMemory: true)
}
