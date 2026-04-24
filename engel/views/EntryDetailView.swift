//
//  EntryDetailView.swift
//  engel
//

import SwiftUI
import SwiftData

struct EntryDetailView: View {
    @Bindable var entry: SDEntry
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var isEditing = false
    @State private var editedContent: String
    @State private var editedGlobe: GlobeType
    @State private var editedPointers: Set<String>
    @State private var isAddingPointer = false
    @State private var newPointerText = ""
    @State private var showDeleteConfirmation = false

    init(entry: SDEntry) {
        self.entry = entry
        _editedContent = State(initialValue: entry.content)
        _editedGlobe = State(initialValue: entry.globeType)
        _editedPointers = State(initialValue: Set(entry.pointers))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Globe badge + date
                HStack {
                    Text(isEditing ? editedGlobe.title.uppercased() : entry.globeType.title.uppercased())
                        .font(AppTypography.caption)
                        .tracking(1.2)
                        .foregroundStyle(globeTint.opacity(0.88))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule().fill(globeTint.opacity(0.12))
                        )

                    Spacer()

                    Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(AppTypography.monoXS)
                        .foregroundStyle(.tertiary)
                }

                // Content
                if isEditing {
                    TextEditor(text: $editedContent)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 160)
                        .font(AppTypography.body)
                        .foregroundStyle(ThemeTokens.colors.ink.opacity(0.92))
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(.secondarySystemBackground))
                        )
                } else {
                    Text(entry.content)
                        .font(AppTypography.display(size: 20, weight: .light))
                        .foregroundStyle(ThemeTokens.colors.ink.opacity(0.92))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Globe selector (edit mode)
                if isEditing {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("GLOBE")
                            .font(AppTypography.caption)
                            .tracking(1.2)
                            .foregroundStyle(ThemeTokens.colors.inkDim)

                        HStack(spacing: 10) {
                            globeChip(label: "Green", globe: .green, color: ThemeTokens.colors.green)
                            globeChip(label: "Mixed", globe: .mixed, color: ThemeTokens.colors.inkDim)
                            globeChip(label: "Red", globe: .red, color: ThemeTokens.colors.red)
                        }
                    }
                }

                // Pointers
                if isEditing || !entry.pointers.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("POINTERS")
                            .font(AppTypography.caption)
                            .tracking(1.2)
                            .foregroundStyle(ThemeTokens.colors.inkDim)

                        WrappingHStack(spacing: 8) {
                            let pointerList = isEditing ? Array(editedPointers).sorted() : entry.pointers.sorted()
                            ForEach(pointerList, id: \.self) { pointer in
                                if isEditing {
                                    Button {
                                        editedPointers.remove(pointer)
                                    } label: {
                                        HStack(spacing: 4) {
                                            Text("#\(pointer)")
                                            Image(systemName: "xmark")
                                                .font(.system(size: 8, weight: .bold))
                                        }
                                        .font(AppTypography.caption)
                                        .foregroundStyle(ThemeTokens.colors.ink)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule().fill(ThemeTokens.colors.ink.opacity(0.1))
                                        )
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    Text("#\(pointer)")
                                        .font(AppTypography.caption)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule().fill(.primary.opacity(0.08))
                                        )
                                }
                            }

                            if isEditing {
                                if isAddingPointer {
                                    HStack(spacing: 4) {
                                        TextField("tag", text: $newPointerText)
                                            .font(AppTypography.caption)
                                            .textFieldStyle(.plain)
                                            .frame(width: 80)
                                            .onSubmit { commitNewPointer() }

                                        Button { commitNewPointer() } label: {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 10, weight: .bold))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .overlay(
                                        Capsule()
                                            .stroke(ThemeTokens.colors.inkDim.opacity(0.4), lineWidth: 1)
                                    )
                                } else {
                                    Button { isAddingPointer = true } label: {
                                        Text("+ add")
                                            .font(AppTypography.caption)
                                            .foregroundStyle(ThemeTokens.colors.inkDim)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .overlay(
                                                Capsule()
                                                    .stroke(ThemeTokens.colors.inkDim.opacity(0.4), lineWidth: 1)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }

                // Source
                HStack(spacing: 6) {
                    Image(systemName: entry.source == "voice" ? "mic.fill" : "pencil")
                        .font(.system(size: 11))
                    Text("Captured via \(entry.source)")
                        .font(AppTypography.monoXS)
                }
                .foregroundStyle(.tertiary)

                Spacer(minLength: 32)

                // Action buttons
                if isEditing {
                    Button {
                        saveEdits()
                    } label: {
                        Text("Save Changes")
                            .font(AppTypography.mono(size: 13, weight: .semibold))
                            .tracking(0.6)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .foregroundStyle(ThemeTokens.colors.bgElevated)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(ThemeTokens.colors.ink)
                    )
                    .buttonStyle(.plain)

                    Button {
                        cancelEdits()
                    } label: {
                        Text("Cancel")
                            .font(AppTypography.mono(size: 13, weight: .regular))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .foregroundStyle(ThemeTokens.colors.inkDim)
                    .buttonStyle(.plain)
                } else {
                    Button {
                        isEditing = true
                    } label: {
                        Text("Edit")
                            .font(AppTypography.mono(size: 13, weight: .semibold))
                            .tracking(0.6)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .foregroundStyle(ThemeTokens.colors.ink)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(ThemeTokens.colors.ink.opacity(0.3), lineWidth: 1)
                    )
                    .buttonStyle(.plain)

                    Button {
                        showDeleteConfirmation = true
                    } label: {
                        Text("Delete Entry")
                            .font(AppTypography.mono(size: 13, weight: .regular))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .foregroundStyle(ThemeTokens.colors.red)
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 24)
            .padding(.bottom, 48)
        }
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete this entry?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                modelContext.delete(entry)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
        }
    }

    // MARK: - Globe chip

    private func globeChip(label: String, globe: GlobeType, color: Color) -> some View {
        let isSelected = editedGlobe == globe
        return Button {
            editedGlobe = globe
        } label: {
            Text(label)
                .font(AppTypography.mono(size: 12, weight: .semibold))
                .tracking(0.4)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundStyle(isSelected ? .white : ThemeTokens.colors.ink)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isSelected ? color : .clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(isSelected ? color : ThemeTokens.colors.inkDim.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private var globeTint: Color {
        let g = isEditing ? editedGlobe : entry.globeType
        switch g {
        case .green: return ThemeTokens.colors.green
        case .red: return ThemeTokens.colors.red
        case .mixed, .unsorted: return ThemeTokens.colors.inkDim
        }
    }

    private func commitNewPointer() {
        let tag = newPointerText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !tag.isEmpty { editedPointers.insert(tag) }
        newPointerText = ""
        isAddingPointer = false
    }

    private func saveEdits() {
        entry.content = editedContent
        entry.globeType = editedGlobe
        entry.pointers = Array(editedPointers)
        isEditing = false
    }

    private func cancelEdits() {
        editedContent = entry.content
        editedGlobe = entry.globeType
        editedPointers = Set(entry.pointers)
        isEditing = false
    }
}

// MARK: - WrappingHStack (flow layout)

struct WrappingHStack: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        layout(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
