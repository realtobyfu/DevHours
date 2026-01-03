//
//  TagBadgeView.swift
//  DevHours
//
//  Reusable tag badge component with color indicator.
//

import SwiftUI

struct TagBadgeView: View {
    let tag: Tag

    var tagColor: Color {
        Color.fromHex(tag.colorHex)
    }

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(tagColor)
                .frame(width: 8, height: 8)
            Text(tag.name)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(tagColor.opacity(0.15))
        )
        .foregroundStyle(tagColor)
    }
}

/// Compact version for tight spaces
struct TagBadgeCompact: View {
    let tag: Tag

    var tagColor: Color {
        Color.fromHex(tag.colorHex)
    }

    var body: some View {
        HStack(spacing: 3) {
            Circle()
                .fill(tagColor)
                .frame(width: 6, height: 6)
            Text(tag.name)
                .font(.caption2)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(tagColor.opacity(0.12))
        )
        .foregroundStyle(tagColor)
    }
}

/// Horizontal flow layout for multiple tags
struct TagsFlowView: View {
    let tags: [Tag]
    var compact: Bool = false

    var body: some View {
        if !tags.isEmpty {
            FlowLayout(spacing: 4) {
                ForEach(tags) { tag in
                    if compact {
                        TagBadgeCompact(tag: tag)
                    } else {
                        TagBadgeView(tag: tag)
                    }
                }
            }
        }
    }
}

/// Multi-select view for picking tags
struct TagMultiSelectView: View {
    let allTags: [Tag]
    @Binding var selectedTags: [Tag]

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(allTags) { tag in
                TagSelectableChip(
                    tag: tag,
                    isSelected: selectedTags.contains { $0.id == tag.id }
                ) {
                    toggleTag(tag)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func toggleTag(_ tag: Tag) {
        if let index = selectedTags.firstIndex(where: { $0.id == tag.id }) {
            selectedTags.remove(at: index)
        } else {
            selectedTags.append(tag)
        }
    }
}

/// Selectable chip for tag picker
struct TagSelectableChip: View {
    let tag: Tag
    let isSelected: Bool
    let onTap: () -> Void

    var tagColor: Color {
        Color.fromHex(tag.colorHex)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption2)
                        .fontWeight(.bold)
                } else {
                    Circle()
                        .fill(tagColor)
                        .frame(width: 8, height: 8)
                }
                Text(tag.name)
                    .font(.subheadline)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? tagColor : tagColor.opacity(0.15))
            )
            .foregroundStyle(isSelected ? .white : tagColor)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Simple horizontal flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var frames: [CGRect] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                // Move to next line
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))

            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            totalWidth = max(totalWidth, currentX - spacing)
            totalHeight = currentY + lineHeight
        }

        return (CGSize(width: totalWidth, height: totalHeight), frames)
    }
}
