//
//  settings.swift
//  engel
//
//  Created by Arssh Kumar on 4/22/26.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.modelContext) private var modelContext

    @AppStorage("prefersDarkMode") private var isDarkModeEnabled = true
    @AppStorage("usesSystemAppearance") private var usesSystemSettings = true
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = true

    @Query(sort: \SDEntry.createdAt, order: .reverse) private var entries: [SDEntry]
    @Query(sort: \SDInsight.createdAt, order: .reverse) private var insights: [SDInsight]

    @State private var showClearConfirmation = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 0) {

                // MARK: - Account

                sectionLabel("ACCOUNT")

                settingsCard {
                    NavigationLink {
                        AccountView()
                    } label: {
                        settingsChevronRow(
                            title: "Account",
                            detail: "Phone, sign-in, privacy",
                            icon: "chevron.right"
                        )
                    }
                    .buttonStyle(.plain)
                }

                // MARK: - Appearance

                sectionLabel("APPEARANCE")

                settingsCard {
                    settingsToggleRow(
                        title: "Match system",
                        detail: usesSystemSettings
                            ? "Follows your iPhone appearance"
                            : "Manual control enabled",
                        isOn: $usesSystemSettings
                    )

                    hairline

                    settingsToggleRow(
                        title: "Dark mode",
                        detail: usesSystemSettings
                            ? "Controlled by system"
                            : (isDarkModeEnabled ? "Always dark" : "Always light"),
                        isOn: $isDarkModeEnabled
                    )
                    .disabled(usesSystemSettings)
                    .opacity(usesSystemSettings ? 0.5 : 1)
                }

                sectionHint("When system settings is on, the app follows your iPhone appearance automatically.")

                // MARK: - Your data

                sectionLabel("YOUR DATA")

                settingsCard {
                    settingsValueRow(title: "Entries", value: "\(entries.count)")
                    hairline
                    settingsValueRow(title: "Insights", value: "\(insights.count)")
                    hairline
                    settingsValueRow(title: "Unique tags", value: "\(uniquePointerCount)")
                }

                // MARK: - Export

                sectionLabel("EXPORT")

                settingsCard {
                    ShareLink(item: exportText) {
                        settingsChevronRow(
                            title: "Export all entries",
                            detail: "Share as Markdown",
                            icon: "square.and.arrow.up"
                        )
                    }
                    .buttonStyle(.plain)

                    hairline

                    ShareLink(item: exportJSON) {
                        settingsChevronRow(
                            title: "Export as JSON",
                            detail: "Raw, portable, archivable",
                            icon: "doc.text"
                        )
                    }
                    .buttonStyle(.plain)
                }

                sectionHint("Export is one tap. Always yours.")

                // MARK: - About

                sectionLabel("ABOUT")

                settingsCard {
                    settingsValueRow(title: "Version", value: "1.0.0")

                    hairline

                    Button {
                        guard let url = URL(string: "https://engelapp.com/privacy") else { return }
                        openURL(url)
                    } label: {
                        settingsChevronRow(
                            title: "Privacy policy",
                            detail: nil,
                            icon: "chevron.right"
                        )
                    }
                    .buttonStyle(.plain)

                    hairline

                    Button {
                        hasCompletedOnboarding = false
                    } label: {
                        settingsChevronRow(
                            title: "Replay onboarding",
                            detail: nil,
                            icon: "chevron.right"
                        )
                    }
                    .buttonStyle(.plain)
                }

                // MARK: - Danger zone

                sectionLabel("DANGER ZONE")

                settingsCard {
                    Button {
                        showClearConfirmation = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Clear all data")
                                    .font(AppTypography.body)
                                    .foregroundStyle(Color(red: 0.784, green: 0.188, blue: 0.188))
                                Text("Deletes entries and insights")
                                    .font(AppTypography.monoXS)
                                    .foregroundStyle(Color(red: 0.784, green: 0.188, blue: 0.188).opacity(0.7))
                            }
                            Spacer()
                            Image(systemName: "trash")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color(red: 0.784, green: 0.188, blue: 0.188))
                        }
                        .frame(minHeight: 56)
                        .padding(.horizontal, 16)
                    }
                    .buttonStyle(.plain)

                    #if DEBUG
                    hairline

                    Button {
                        loadSampleData()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Load sample data")
                                    .font(AppTypography.body)
                                    .foregroundStyle(ThemeTokens.colors.green)
                                Text("13 entries, 2 insights")
                                    .font(AppTypography.monoXS)
                                    .foregroundStyle(ThemeTokens.colors.inkDim)
                            }
                            Spacer()
                            Image(systemName: "tray.and.arrow.down")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(ThemeTokens.colors.green)
                        }
                        .frame(minHeight: 56)
                        .padding(.horizontal, 16)
                    }
                    .buttonStyle(.plain)
                    #endif
                }

                sectionHint("Data deletion can\u{2019}t be undone. There is no server-side backup.")

                // MARK: - Footer

                VStack(spacing: 8) {
                    Text("Authority stays with the human.")
                        .font(Font.custom("Fraunces", size: 14).italic())
                        .foregroundStyle(ThemeTokens.colors.inkDim)

                    Text("ENGEL \u{00B7} TWO GLOBES")
                        .font(AppTypography.mono(size: 10, weight: .regular))
                        .tracking(1.0)
                        .foregroundStyle(ThemeTokens.colors.inkFaint)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 32)
                .padding(.bottom, 48)
            }
            .padding(.horizontal, 18)
        }
        .background(Color(.systemBackground))
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                HStack(spacing: 14) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(ThemeTokens.colors.ink)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(Color(.secondarySystemBackground))
                                    .overlay(
                                        Circle()
                                            .stroke(ThemeTokens.colors.line, lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)

                    Text("Settings")
                        .font(AppTypography.display(size: 28, weight: .regular))
                        .foregroundStyle(ThemeTokens.colors.ink)
                }
            }
        }
        .alert("Clear all data?", isPresented: $showClearConfirmation) {
            Button("Clear", role: .destructive) {
                clearAllData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete all entries and insights. Cannot be undone.")
        }
    }

    // MARK: - Card components

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(AppTypography.mono(size: 10, weight: .regular))
            .tracking(1.0)
            .foregroundStyle(ThemeTokens.colors.inkDim)
            .padding(.top, 28)
            .padding(.bottom, 10)
            .padding(.leading, 4)
    }

    private func sectionHint(_ text: String) -> some View {
        Text(text)
            .font(AppTypography.monoXS)
            .foregroundStyle(ThemeTokens.colors.inkDim)
            .padding(.top, 8)
            .padding(.leading, 4)
    }

    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(ThemeTokens.colors.line, lineWidth: 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var hairline: some View {
        Rectangle()
            .fill(ThemeTokens.colors.line.opacity(0.4))
            .frame(height: 1)
            .padding(.horizontal, 16)
    }

    // MARK: - Row components

    private func settingsToggleRow(title: String, detail: String, isOn: Binding<Bool>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(AppTypography.body)
                    .foregroundStyle(ThemeTokens.colors.ink)
                Text(detail)
                    .font(AppTypography.monoXS)
                    .foregroundStyle(ThemeTokens.colors.inkDim)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(ThemeTokens.colors.green)
        }
        .frame(minHeight: 56)
        .padding(.horizontal, 16)
    }

    private func settingsValueRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(AppTypography.body)
                .foregroundStyle(ThemeTokens.colors.ink)
            Spacer()
            Text(value)
                .font(AppTypography.monoSM)
                .foregroundStyle(ThemeTokens.colors.inkDim)
        }
        .frame(minHeight: 56)
        .padding(.horizontal, 16)
    }

    private func settingsChevronRow(title: String, detail: String?, icon: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(AppTypography.body)
                    .foregroundStyle(ThemeTokens.colors.ink)
                if let detail {
                    Text(detail)
                        .font(AppTypography.monoXS)
                        .foregroundStyle(ThemeTokens.colors.inkDim)
                }
            }
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(ThemeTokens.colors.inkDim)
        }
        .frame(minHeight: 56)
        .padding(.horizontal, 16)
    }

    // MARK: - Sample data

    private func loadSampleData() {
        let now = Date()

        let g1 = SDEntry(content: "Had the best morning run in weeks. The air was cold and sharp and I felt completely present for once.", source: "voice", globe: .green, pointers: ["running", "presence", "mornings"])
        g1.createdAt = now.addingTimeInterval(-1 * 86400)

        let g2 = SDEntry(content: "Finally shipped the feature I'd been stuck on. The fix was embarrassingly simple \u{2014} just needed to step away.", source: "text", globe: .green, pointers: ["work", "shipping", "breakthroughs"])
        g2.createdAt = now.addingTimeInterval(-2 * 86400)

        let g3 = SDEntry(content: "Long call with Dad. He told me about his first job out of college. I\u{2019}d never heard that story before.", source: "voice", globe: .green, pointers: ["family", "dad", "connection"])
        g3.createdAt = now.addingTimeInterval(-3 * 86400)

        let g4 = SDEntry(content: "Cooked something real for the first time in two weeks. Nothing fancy, just eggs and greens, but it felt like taking care of myself.", source: "text", globe: .green, pointers: ["cooking", "selfcare"])
        g4.createdAt = now.addingTimeInterval(-5 * 86400)

        let g5 = SDEntry(content: "Sat in the park for twenty minutes doing nothing. Didn\u{2019}t check my phone once.", source: "text", globe: .green, pointers: ["presence", "rest"])
        g5.createdAt = now.addingTimeInterval(-7 * 86400)

        let r1 = SDEntry(content: "The meeting went sideways again. I keep preparing carefully and then staying silent when it matters.", source: "voice", globe: .red, pointers: ["work", "speaking up", "frustration"])
        r1.createdAt = now.addingTimeInterval(-1.5 * 86400)

        let r2 = SDEntry(content: "Couldn\u{2019}t sleep until 3am. Brain wouldn\u{2019}t stop replaying that conversation. I know it doesn\u{2019}t matter but my body doesn\u{2019}t seem to agree.", source: "text", globe: .red, pointers: ["sleep", "overthinking", "anxiety"])
        r2.createdAt = now.addingTimeInterval(-3 * 86400)

        let r3 = SDEntry(content: "Scrolled for two hours instead of working on the thing I actually care about. The usual pattern.", source: "text", globe: .red, pointers: ["distraction", "avoidance", "work"])
        r3.createdAt = now.addingTimeInterval(-4 * 86400)

        let r4 = SDEntry(content: "Snapped at a friend over something tiny. I think I\u{2019}m more drained than I realize.", source: "voice", globe: .red, pointers: ["relationships", "irritability", "energy"])
        r4.createdAt = now.addingTimeInterval(-6 * 86400)

        let r5 = SDEntry(content: "Everything feels like it takes twice the effort right now. Not sad exactly, just heavy.", source: "text", globe: .red, pointers: ["energy", "heaviness"])
        r5.createdAt = now.addingTimeInterval(-8 * 86400)

        let m1 = SDEntry(content: "Got feedback on the design. Some of it stung but honestly the critique was right. I can see the path to making it better now.", source: "text", globe: .mixed, pointers: ["work", "feedback", "growth"])
        m1.createdAt = now.addingTimeInterval(-2.5 * 86400)

        let m2 = SDEntry(content: "Moved to a new neighborhood. Exciting but I already miss the old coffee shop and the people who knew my name.", source: "voice", globe: .mixed, pointers: ["change", "home", "belonging"])
        m2.createdAt = now.addingTimeInterval(-9 * 86400)

        let u1 = SDEntry(content: "I keep thinking about that quote \u{2014} \u{2018}the days are long but the years are short.\u{2019} Not sure if that\u{2019}s comforting or terrifying.", source: "text", globe: .unsorted, pointers: ["time", "reflection"])
        u1.createdAt = now.addingTimeInterval(-4.5 * 86400)

        let allEntries = [g1, g2, g3, g4, g5, r1, r2, r3, r4, r5, m1, m2, u1]
        for entry in allEntries {
            modelContext.insert(entry)
        }

        let i1 = SDInsight(
            insightType: .asymmetry,
            title: "The green globe is louder",
            body: "Your recent fragments lean green \u{2014} energy, presence, small wins. The red globe has been quieter, though the entries there carry weight. Not a problem, just a pattern to notice.",
            evidenceSummary: "5 green, 5 red, 2 mixed across 13 entries"
        )
        i1.createdAt = now.addingTimeInterval(-7 * 86400)

        let i2 = SDInsight(
            insightType: .contradiction,
            title: "Work fuels you and drains you",
            body: "The tag #work appears in both globes. Shipping gives you energy; meetings and avoidance drain it. The same part of life is doing both.",
            evidenceSummary: "3 entries tagged #work across both globes"
        )
        i2.createdAt = now.addingTimeInterval(-14 * 86400)

        modelContext.insert(i1)
        modelContext.insert(i2)
    }

    private func clearAllData() {
        for entry in entries { modelContext.delete(entry) }
        for insight in insights { modelContext.delete(insight) }
    }

    // MARK: - Export helpers

    private var uniquePointerCount: Int {
        Set(entries.flatMap { $0.pointers }).count
    }

    private var exportText: String {
        var lines = [
            "# Two Globes Export",
            "",
            "Exported: \(Date().formatted())",
            "Total entries: \(entries.count)",
            ""
        ]

        let grouped: [(String, [SDEntry])] = [
            ("Green", entries.filter { $0.globe == "green" }),
            ("Red", entries.filter { $0.globe == "red" }),
            ("Mixed", entries.filter { $0.globe == "mixed" }),
            ("Unsorted", entries.filter { $0.globe == "unsorted" })
        ]

        for (label, group) in grouped where !group.isEmpty {
            lines.append("## \(label) Globe (\(group.count))")
            lines.append("")
            for entry in group {
                lines.append("- **\(entry.createdAt.formatted(date: .abbreviated, time: .shortened))**")
                lines.append("  \(entry.content)")
                if !entry.pointers.isEmpty {
                    lines.append("  Tags: \(entry.pointers.map { "#\($0)" }.joined(separator: " "))")
                }
                lines.append("")
            }
        }

        if !insights.isEmpty {
            lines.append("## Insights (\(insights.count))")
            lines.append("")
            for insight in insights {
                lines.append("- **\(insight.title)** (\(insight.type.title))")
                lines.append("  \(insight.body)")
                lines.append("  _\(insight.evidenceSummary)_")
                lines.append("")
            }
        }

        return lines.joined(separator: "\n")
    }

    private var exportJSON: String {
        struct ExportEntry: Encodable {
            let content: String
            let source: String
            let globe: String
            let pointers: [String]
            let createdAt: String
        }

        let exportEntries = entries.map { entry in
            ExportEntry(
                content: entry.content,
                source: entry.source,
                globe: entry.globe,
                pointers: entry.pointers,
                createdAt: entry.createdAt.ISO8601Format()
            )
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(exportEntries),
              let json = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return json
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(for: [SDEntry.self, SDInsight.self], inMemory: true)
}
