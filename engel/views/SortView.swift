//
//  SortView.swift
//  engel
//

import SwiftUI
import SwiftData

struct SortView: View {
    let transcriptResponse: TranscriptResponse
    let source: String
    let onDone: () -> Void

    @Environment(\.modelContext) private var modelContext

    @State private var selectedGlobe: GlobeType
    @State private var selectedPointers: Set<String>
    @State private var isAddingPointer = false
    @State private var newPointerText = ""

    init(
        transcriptResponse: TranscriptResponse,
        source: String,
        onDone: @escaping () -> Void
    ) {
        self.transcriptResponse = transcriptResponse
        self.source = source
        self.onDone = onDone

        let initialGlobe: GlobeType = switch transcriptResponse.suggestedGlobe {
        case .green: .green
        case .red: .red
        case .mixed: .mixed
        default: .mixed
        }
        _selectedGlobe = State(initialValue: initialGlobe)
        _selectedPointers = State(initialValue: Set(transcriptResponse.suggestedPointers))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sort")
                        .font(AppTypography.display(size: 24, weight: .regular))
                        .foregroundStyle(ThemeTokens.colors.ink)

                    Text("AI suggested. You decide.")
                        .font(AppTypography.monoXS)
                        .foregroundStyle(ThemeTokens.colors.inkDim)
                }

                // Fragment text
                Text(transcriptResponse.transcript)
                    .font(AppTypography.display(size: 20, weight: .light))
                    .italic()
                    .foregroundStyle(ThemeTokens.colors.ink.opacity(0.88))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)

                // Low confidence warning
                if transcriptResponse.confidence < 0.7 {
                    Text("low confidence \u{00B7} review carefully")
                        .font(AppTypography.caption)
                        .tracking(0.4)
                        .foregroundStyle(ThemeTokens.colors.inkDim)
                }

                // Globe assignment
                VStack(alignment: .leading, spacing: 12) {
                    Text("ASSIGN TO GLOBE")
                        .font(AppTypography.caption)
                        .tracking(1.2)
                        .foregroundStyle(ThemeTokens.colors.inkDim)

                    HStack(spacing: 12) {
                        globeButton(label: "Green", globe: .green, color: ThemeTokens.colors.green)
                        globeButton(label: "Mixed", globe: .mixed, color: ThemeTokens.colors.inkDim)
                        globeButton(label: "Red", globe: .red, color: ThemeTokens.colors.red)
                    }
                }

                // Skip link
                Button {
                    onDone()
                } label: {
                    Text("skip for now")
                        .font(AppTypography.monoSM)
                        .foregroundStyle(ThemeTokens.colors.inkDim)
                        .underline()
                }
                .buttonStyle(.plain)

                // Pointer suggestions
                if !transcriptResponse.suggestedPointers.isEmpty || !selectedPointers.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("POINTERS")
                            .font(AppTypography.caption)
                            .tracking(1.2)
                            .foregroundStyle(ThemeTokens.colors.inkDim)

                        FlowLayout(spacing: 8) {
                            ForEach(allPointers, id: \.self) { pointer in
                                pointerChip(pointer)
                            }

                            addPointerChip
                        }
                    }
                }

                // Save button
                Button {
                    save()
                } label: {
                    Text("Save to globe")
                        .font(AppTypography.mono(size: 13, weight: .semibold))
                        .tracking(0.6)
                        .frame(maxWidth: .infinity)
                }
                .foregroundStyle(ThemeTokens.colors.bgElevated)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(ThemeTokens.colors.ink)
                )
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .padding(.top, 24)
            .padding(.bottom, 48)
        }
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Globe button

    private func globeButton(label: String, globe: GlobeType, color: Color) -> some View {
        let isSelected = selectedGlobe == globe

        return Button {
            selectedGlobe = globe
        } label: {
            Text(label)
                .font(AppTypography.mono(size: 13, weight: .semibold))
                .tracking(0.6)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(isSelected ? .white : ThemeTokens.colors.ink)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isSelected ? color : .clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isSelected ? color : ThemeTokens.colors.inkDim.opacity(0.4), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Pointer chips

    private var allPointers: [String] {
        var combined = transcriptResponse.suggestedPointers
        for p in selectedPointers where !combined.contains(p) {
            combined.append(p)
        }
        return combined
    }

    private func pointerChip(_ pointer: String) -> some View {
        let isSelected = selectedPointers.contains(pointer)

        return Button {
            if isSelected {
                selectedPointers.remove(pointer)
            } else {
                selectedPointers.insert(pointer)
            }
        } label: {
            Text("#\(pointer)")
                .font(AppTypography.caption)
                .foregroundStyle(isSelected ? ThemeTokens.colors.bgElevated : ThemeTokens.colors.inkDim)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? ThemeTokens.colors.ink : .clear)
                )
                .overlay(
                    Capsule()
                        .stroke(isSelected ? .clear : ThemeTokens.colors.inkDim.opacity(0.4), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var addPointerChip: some View {
        Group {
            if isAddingPointer {
                HStack(spacing: 4) {
                    TextField("tag", text: $newPointerText)
                        .font(AppTypography.caption)
                        .textFieldStyle(.plain)
                        .frame(width: 80)
                        .onSubmit {
                            commitNewPointer()
                        }

                    Button {
                        commitNewPointer()
                    } label: {
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
                Button {
                    isAddingPointer = true
                } label: {
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

    private func commitNewPointer() {
        let tag = newPointerText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !tag.isEmpty {
            selectedPointers.insert(tag)
        }
        newPointerText = ""
        isAddingPointer = false
    }

    // MARK: - Save

    private func save() {
        let entry = SDEntry(
            content: transcriptResponse.transcript,
            source: source,
            globe: selectedGlobe,
            pointers: Array(selectedPointers)
        )
        modelContext.insert(entry)
        onDone()
    }
}

// MARK: - FlowLayout

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
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
