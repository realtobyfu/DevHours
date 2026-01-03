//
//  TagsListView.swift
//  DevHours
//
//  Manage colored tags for categorizing time entries.
//

import SwiftUI
import SwiftData

struct TagsListView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Tag.name)
    private var tags: [Tag]

    @State private var showAddSheet = false
    @State private var selectedTag: Tag?

    var body: some View {
        List {
            if tags.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.tertiary)

                    VStack(spacing: 4) {
                        Text("No tags yet")
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text("Create tags to categorize your time entries")
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
                ForEach(tags) { tag in
                    TagRow(tag: tag)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedTag = tag
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteTag(tag)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
        .navigationTitle("Tags")
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
                .accessibilityLabel("Add tag")
            }
        }
        .sheet(isPresented: $showAddSheet) {
            TagEditSheet(tag: nil)
        }
        .sheet(item: $selectedTag) { tag in
            TagEditSheet(tag: tag)
        }
    }

    private func deleteTag(_ tag: Tag) {
        modelContext.delete(tag)
        do {
            try modelContext.save()
        } catch {
            print("Error deleting tag: \(error)")
        }
    }
}

struct TagRow: View {
    let tag: Tag

    var tagColor: Color {
        Color.fromHex(tag.colorHex)
    }

    var body: some View {
        HStack {
            Circle()
                .fill(tagColor)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 4) {
                Text(tag.name)
                    .font(.headline)

                Text("\(tag.timeEntries.count) entries")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
        TagsListView()
            .modelContainer(for: Tag.self, inMemory: true)
    }
}
