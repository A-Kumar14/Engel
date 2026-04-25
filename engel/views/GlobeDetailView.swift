//
//  GlobeDetailView.swift
//  engel
//

import SwiftUI
import SwiftData

struct GlobeDetailView: View {
    let tone: GlobeTone
    @Binding var navigationPath: NavigationPath

    @Query private var entries: [SDEntry]

    init(tone: GlobeTone, navigationPath: Binding<NavigationPath>) {
        self.tone = tone
        self._navigationPath = navigationPath
        let key = tone.storageKey
        _entries = Query(
            filter: #Predicate<SDEntry> { entry in entry.globe == key },
            sort: \SDEntry.createdAt,
            order: .reverse
        )
    }

    // MARK: - Computed

    private var allTags: [String] {
        var seen = Set<String>()
        var result: [String] = []
        for entry in entries {
            for tag in entry.pointers {
                if seen.insert(tag).inserted {
                    result.append(tag)
                }
            }
        }
        return result
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(.systemBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    topBar
                    heroBlock
                    editorialLead
                    if entries.isEmpty {
                        emptyState
                    } else {
                        recurringTagsSection
                        fragmentsSection
                    }
                    footerNote
                }
                .padding(.bottom, 130)
            }

            glassNavBar
                .padding(.horizontal, 18)
                .padding(.bottom, 16)
        }
        .navigationBarHidden(true)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 12) {
            // Back button
            Button {
                navigationPath.removeLast()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(ThemeTokens.colors.ink)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(.primary.opacity(0.12), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            // Title block
            VStack(alignment: .leading, spacing: 2) {
                Text(tone.label)
                    .font(AppTypography.mono(size: 10, weight: .semibold))
                    .tracking(1)
                    .textCase(.uppercase)
                    .foregroundStyle(tone.base)

                Text(tone.hint)
                    .font(AppTypography.mono(size: 11, weight: .regular))
                    .foregroundStyle(ThemeTokens.colors.inkDim)
            }

            Spacer()

            // Filter button
            Button {
                // Filter action — no-op for now
            } label: {
                Image(systemName: "line.horizontal.decrease")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(ThemeTokens.colors.ink)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(.primary.opacity(0.12), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 66)
        .padding(.horizontal, 18)
        .padding(.bottom, 12)
    }

    // MARK: - Hero Block

    private var heroBlock: some View {
        VStack(spacing: 0) {
            GlobeView(tone: tone, size: 180, entryCount: entries.count, pulse: true)
                .frame(width: 180, height: 180)

            Spacer().frame(height: 24)

            Text("\(entries.count)")
                .font(AppTypography.display(size: 42, weight: .light))
                .foregroundStyle(ThemeTokens.colors.ink)

            Text("\(entries.count == 1 ? "fragment" : "fragments") \u{00B7} this week")
                .font(AppTypography.mono(size: 12, weight: .regular))
                .tracking(0.4)
                .foregroundStyle(ThemeTokens.colors.inkDim)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 18)
        .padding(.bottom, 24)
    }

    // MARK: - Editorial Lead

    private var editorialLead: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(.primary.opacity(0.06))
                .frame(height: 1)

            Text(tone.editorial)
                .font(Font.custom("Fraunces", size: 20).weight(.light).italic())
                .foregroundStyle(ThemeTokens.colors.inkDim)
                .lineSpacing(20 * 0.4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .padding(.vertical, 16)

            Rectangle()
                .fill(.primary.opacity(0.06))
                .frame(height: 1)
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 18)
    }

    // MARK: - Recurring Tags

    private var recurringTagsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("RECURRING TAGS")
                .font(AppTypography.mono(size: 10, weight: .regular))
                .tracking(1)
                .textCase(.uppercase)
                .foregroundStyle(ThemeTokens.colors.inkDim)

            if allTags.isEmpty {
                Text("No tags yet")
                    .font(AppTypography.mono(size: 11, weight: .regular))
                    .foregroundStyle(ThemeTokens.colors.inkDim)
            } else {
                WrappingHStack(spacing: 6) {
                    ForEach(allTags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(AppTypography.mono(size: 11, weight: .regular))
                            .foregroundStyle(ThemeTokens.colors.ink)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color(.secondarySystemBackground))
                                    .overlay(
                                        Capsule()
                                            .stroke(.primary.opacity(0.10), lineWidth: 1)
                                    )
                            )
                    }
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 24)
    }

    // MARK: - Fragments List

    private var fragmentsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("FRAGMENTS")
                .font(AppTypography.mono(size: 10, weight: .regular))
                .tracking(1)
                .textCase(.uppercase)
                .foregroundStyle(ThemeTokens.colors.inkDim)
                .padding(.horizontal, 18)

            LazyVStack(spacing: 10) {
                ForEach(entries) { entry in
                    fragmentCard(entry: entry)
                        .onTapGesture {
                            // Entry detail navigation — no-op for now
                        }
                }
            }
            .padding(.horizontal, 18)
        }
    }

    private func fragmentCard(entry: SDEntry) -> some View {
        HStack(spacing: 0) {
            // Accent bar
            RoundedRectangle(cornerRadius: 1)
                .fill(tone.base)
                .frame(width: 2)
                .padding(.vertical, 14)

            VStack(alignment: .leading, spacing: 0) {
                Text(relativeDate(entry.createdAt))
                    .font(AppTypography.mono(size: 10, weight: .regular))
                    .tracking(0.6)
                    .textCase(.uppercase)
                    .foregroundStyle(ThemeTokens.colors.inkDim)

                Spacer().frame(height: 8)

                Text(entry.content)
                    .font(AppTypography.mono(size: 14, weight: .regular))
                    .foregroundStyle(ThemeTokens.colors.ink)
                    .lineSpacing(14 * 0.55)
                    .lineLimit(6)

                if !entry.pointers.isEmpty {
                    Spacer().frame(height: 10)

                    WrappingHStack(spacing: 6) {
                        ForEach(entry.pointers, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(AppTypography.mono(size: 10, weight: .regular))
                                .foregroundStyle(ThemeTokens.colors.inkDim)
                        }
                    }
                }
            }
            .padding(.leading, 12)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.primary.opacity(0.10), lineWidth: 1)
                )
        )
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 14) {
            Text("NOTHING HERE YET")
                .font(AppTypography.mono(size: 10, weight: .regular))
                .tracking(1)
                .textCase(.uppercase)
                .foregroundStyle(ThemeTokens.colors.inkDim)

            Text("Nothing on your mind in this space \u{2014} and that\u{2019}s fine.")
                .font(Font.custom("Fraunces", size: 16).italic())
                .foregroundStyle(ThemeTokens.colors.inkDim)
                .multilineTextAlignment(.center)

            Button {
                navigationPath.append(AppDestination.sortText(fragment: ""))
            } label: {
                Text("Write a fragment")
                    .font(AppTypography.mono(size: 12, weight: .semibold))
                    .tracking(0.4)
                    .foregroundStyle(ThemeTokens.colors.ink)
                    .frame(minWidth: 44, minHeight: 44)
                    .padding(.horizontal, 16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(.primary.opacity(0.10), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 18)
        .padding(.vertical, 40)
    }

    // MARK: - Footer

    private var footerNote: some View {
        VStack(spacing: 6) {
            Text("Every fragment stays yours.")
                .font(Font.custom("Fraunces", size: 13).italic())
                .foregroundStyle(ThemeTokens.colors.inkDim)
                .lineSpacing(13 * 0.5)

            Button {
                // Export — no-op for now
            } label: {
                Text("EXPORT \u{00B7} ONE TAP")
                    .font(AppTypography.mono(size: 10, weight: .regular))
                    .tracking(0.8)
                    .textCase(.uppercase)
                    .foregroundStyle(ThemeTokens.colors.inkFaint)
                    .frame(minHeight: 44)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 28)
        .padding(.horizontal, 18)
    }

    // MARK: - Glass Nav Bar

    private var glassNavBar: some View {
        HStack(spacing: 8) {
            navBarItem(icon: "circle.grid.2x2.fill", label: "Home", isSelected: true)
            navBarItem(icon: "square.and.pencil", label: "Write", isSelected: false)
            navBarItem(icon: "tray.full", label: "Entries", isSelected: false)
            navBarItem(icon: "sparkles", label: "Insights", isSelected: false)
        }
        .padding(8)
        .background(
            Capsule()
                .fill(.ultraThinMaterial.opacity(0.88))
                .overlay(
                    Capsule()
                        .stroke(ThemeTokens.colors.ink.opacity(0.12), lineWidth: 0.8)
                )
        )
        .shadow(color: ThemeTokens.colors.ink.opacity(0.08), radius: 18, y: 10)
    }

    private func navBarItem(icon: String, label: String, isSelected: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))

            if isSelected {
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
            }
        }
        .foregroundStyle(isSelected ? ThemeTokens.colors.ink : ThemeTokens.colors.ink.opacity(0.72))
        .padding(.horizontal, isSelected ? 16 : 14)
        .padding(.vertical, 13)
        .background(
            Capsule()
                .fill(isSelected ? ThemeTokens.colors.ink.opacity(0.10) : .clear)
        )
    }

    // MARK: - Date Helper

    private func relativeDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return "Today \u{00B7} \(formatter.string(from: date))"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let days = calendar.dateComponents([.day], from: date, to: Date()).day ?? 0
            if days < 7 {
                return "\(days)d ago"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d"
                return formatter.string(from: date)
            }
        }
    }
}

// MARK: - Globe View (animated)

struct GlobeView: View {
    let tone: GlobeTone
    let size: CGFloat
    let entryCount: Int
    let pulse: Bool

    @State private var isPulsing = false

    private var base: Color { tone.base }
    private var edge: Color { tone.edge }

    var body: some View {
        ZStack {
            // Glow
            Circle()
                .fill(base.opacity(0.18))
                .blur(radius: 14)
                .scaleEffect(isPulsing ? 1.25 : 1.2)

            // Sphere
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            base.opacity(0.98),
                            base.opacity(0.62),
                            edge.opacity(0.92),
                            Color.black.opacity(0.95)
                        ],
                        center: UnitPoint(x: 0.32, y: 0.28),
                        startRadius: 2,
                        endRadius: size * 0.39
                    )
                )
                .overlay(Circle().stroke(base.opacity(0.22), lineWidth: 1))
                .overlay {
                    ForEach(0..<min(max(entryCount, 4), 16), id: \.self) { i in
                        let angle = Double(i) * 2.39996323
                        let r = 14 + Double((i * 9) % 38)
                        Circle()
                            .fill(Color.white.opacity(0.75))
                            .frame(width: 3, height: 3)
                            .offset(x: cos(angle) * r, y: sin(angle) * r)
                    }
                }
        }
        .frame(width: size, height: size)
        .onAppear {
            guard pulse else { return }
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}
