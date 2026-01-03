//
//  TagEditSheet.swift
//  DevHours
//
//  Add or edit a tag with name and color.
//

import SwiftUI
import SwiftData

struct TagEditSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let tag: Tag?

    @State private var name: String = ""
    @State private var selectedColorHex: String = TagColors.defaultHex

    private var isEditing: Bool {
        tag != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Tag name", text: $name)
                } header: {
                    Text("Name")
                }

                Section {
                    ColorGridPicker(selectedHex: $selectedColorHex)
                } header: {
                    Text("Color")
                }

                Section {
                    HStack {
                        Text("Preview")
                        Spacer()
                        if !name.trimmingCharacters(in: .whitespaces).isEmpty {
                            previewBadge
                        } else {
                            Text("Enter a name")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Tag" : "New Tag")
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
                if let tag = tag {
                    name = tag.name
                    selectedColorHex = tag.colorHex
                }
            }
        }
    }

    private var previewBadge: some View {
        let color = Color.fromHex(selectedColorHex)
        return HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(name.trimmingCharacters(in: .whitespaces))
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
        )
        .foregroundStyle(color)
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)

        if let tag = tag {
            // Update existing
            tag.name = trimmedName
            tag.colorHex = selectedColorHex
        } else {
            // Create new
            let newTag = Tag(name: trimmedName, colorHex: selectedColorHex)
            modelContext.insert(newTag)
        }

        do {
            try modelContext.save()
        } catch {
            print("Error saving tag: \(error)")
        }

        dismiss()
    }
}

struct ColorGridPicker: View {
    @Binding var selectedHex: String

    private let columns = [
        GridItem(.adaptive(minimum: 44), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(TagColors.presets) { preset in
                ColorCircle(
                    color: preset.color,
                    isSelected: selectedHex == preset.hex
                )
                .onTapGesture {
                    selectedHex = preset.hex
                }
                .accessibilityLabel(preset.name)
                .accessibilityAddTraits(selectedHex == preset.hex ? .isSelected : [])
            }
        }
        .padding(.vertical, 8)
    }
}

struct ColorCircle: View {
    let color: Color
    let isSelected: Bool

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 36, height: 36)
            .overlay(
                Circle()
                    .strokeBorder(Color.white, lineWidth: isSelected ? 3 : 0)
            )
            .overlay(
                Circle()
                    .strokeBorder(color.opacity(0.3), lineWidth: isSelected ? 1 : 0)
                    .padding(2)
            )
            .shadow(color: isSelected ? color.opacity(0.4) : .clear, radius: 4)
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

#Preview("New Tag") {
    TagEditSheet(tag: nil)
        .modelContainer(for: Tag.self, inMemory: true)
}
