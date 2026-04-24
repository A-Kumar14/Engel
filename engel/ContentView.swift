//
//  ContentView.swift
//  engel
//
//  Created by Arssh Kumar on 4/21/26.
//

import SwiftUI
import SwiftData

// MARK: - Tab enum

private enum HomeTab: String, CaseIterable, Identifiable {
    case home
    case capture
    case entries
    case insights

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .capture: return "Write"
        case .entries: return "Entries"
        case .insights: return "Insights"
        }
    }

    var icon: String {
        switch self {
        case .home: return "circle.grid.2x2.fill"
        case .capture: return "square.and.pencil"
        case .entries: return "tray.full"
        case .insights: return "sparkles"
        }
    }
}

// MARK: - Globe tone (green / red only)

enum GlobeTone: String, Hashable {
    case green
    case red

    var storageKey: String { rawValue }

    var edge: Color {
        switch self {
        case .green: return ThemeTokens.colors.greenDeep
        case .red: return ThemeTokens.colors.redDeep
        }
    }

    var base: Color {
        switch self {
        case .green: return ThemeTokens.colors.green
        case .red: return ThemeTokens.colors.red
        }
    }

    var label: String {
        switch self {
        case .green: return "GREEN GLOBE"
        case .red: return "RED GLOBE"
        }
    }

    var hint: String {
        switch self {
        case .green: return "energy \u{00B7} wins \u{00B7} aliveness"
        case .red: return "friction \u{00B7} heaviness \u{00B7} stuck"
        }
    }

    var editorial: String {
        switch self {
        case .green: return "What gave you energy this week."
        case .red: return "What felt heavy this week."
        }
    }
}

// MARK: - Navigation destinations

enum AppDestination: Hashable {
    case settings
    case sortVoice(TranscriptResponse)
    case sortText(fragment: String)
    case pointerCloud
    case globeDetail(GlobeTone)
}

// MARK: - ContentView

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext

    // SwiftData queries
    @Query(sort: \SDEntry.createdAt, order: .reverse) private var allEntries: [SDEntry]
    @Query(sort: \SDInsight.createdAt, order: .reverse) private var insights: [SDInsight]

    // State
    @State private var selectedTab: HomeTab = .home
    @State private var viewModel = HomeViewModel()
    @State private var navigationPath = NavigationPath()
    @State private var recordingManager = RecordingManager()
    @State private var recordingError: String?

    // Entries filtering
    @State private var searchText = ""
    @State private var globeFilter: GlobeType? = nil

    // Entry detail sheet
    @State private var selectedEntry: SDEntry?

    // MARK: - Computed

    private var greenCount: Int { allEntries.filter { $0.globe == "green" }.count }
    private var redCount: Int { allEntries.filter { $0.globe == "red" }.count }
    private var unsortedCount: Int { allEntries.filter { $0.globe == "unsorted" || $0.globe == "mixed" }.count }

    private var filteredEntries: [SDEntry] {
        var result = allEntries
        if let globeFilter {
            if globeFilter == .unsorted {
                result = result.filter { $0.globe == "unsorted" || $0.globe == "mixed" }
            } else {
                result = result.filter { $0.globeType == globeFilter }
            }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.content.localizedCaseInsensitiveContains(searchText)
                || $0.pointers.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        return result
    }

    private var canGenerateInsight: Bool {
        guard allEntries.count >= 3 else { return false }
        guard let latest = insights.first else { return true }
        return latest.createdAt.addingTimeInterval(7 * 86400) < Date()
    }

    private var nextInsightDate: Date? {
        guard let latest = insights.first else { return nil }
        let next = latest.createdAt.addingTimeInterval(7 * 86400)
        return next > Date() ? next : nil
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack(alignment: .bottom) {
                Color(.systemBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    topBar

                    Group {
                        switch selectedTab {
                        case .home:
                            homePage
                        case .capture:
                            capturePage
                        case .entries:
                            entriesPage
                        case .insights:
                            insightsPage
                        }
                    }
                }

                glassNavBar
                    .padding(.horizontal, 18)
                    .padding(.bottom, 16)
            }
            .navigationDestination(for: AppDestination.self) { destination in
                switch destination {
                case .settings:
                    SettingsView()
                case .sortVoice(let response):
                    SortView(
                        transcriptResponse: response,
                        source: "voice"
                    ) {
                        navigationPath = NavigationPath()
                    }
                case .sortText(let fragment):
                    SortView(
                        transcriptResponse: TranscriptResponse(
                            transcript: fragment,
                            suggestedGlobe: .unsorted,
                            suggestedPointers: [],
                            confidence: 0.0
                        ),
                        source: "text"
                    ) {
                        navigationPath = NavigationPath()
                        viewModel.draftEntry = ""
                    }
                case .pointerCloud:
                    PointerCloudView()
                case .globeDetail(let tone):
                    GlobeDetailView(tone: tone, navigationPath: $navigationPath)
                }
            }
        }
        .sheet(item: $selectedEntry) { entry in
            NavigationStack {
                EntryDetailView(entry: entry)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { selectedEntry = nil }
                        }
                    }
            }
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    if selectedTab == .home {
                        Text("Engel")
                            .font(AppTypography.display(size: 36, weight: .regular))
                            .kerning(-0.36)
                            .foregroundStyle(.primary)
                            .padding(.top, 20)

                        Text(headerSubtitle)
                            .font(AppTypography.monoXS)
                            .foregroundStyle(.secondary)
                            .padding(.top, 10)
                    } else {
                        Text(selectedTab.title)
                            .font(AppTypography.display(size: 24, weight: .light))
                            .foregroundStyle(.primary)

                        Text(headerSubtitle)
                            .font(AppTypography.monoXS)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Menu {
                    Button {
                        navigationPath.append(AppDestination.settings)
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }

                    Button {
                        navigationPath.append(AppDestination.pointerCloud)
                    } label: {
                        Label("Manage Tags", systemImage: "tag")
                    }
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(ThemeTokens.colors.ink.opacity(0.8))
                }
                .buttonStyle(
                    OptionGlassButtonStyle(
                        strokeColor: ThemeTokens.colors.ink.opacity(0.3),
                        shadowColor: ThemeTokens.colors.ink.opacity(0.12)
                    )
                )
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 16)

            Divider()
        }
    }

    // MARK: - Home page (Variant A: Calm Accessible)

    private var homePage: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Greeting
                    VStack(alignment: .leading, spacing: 6) {
                        Text(greetingTitle)
                            .font(AppTypography.display(size: 22, weight: .light))
                            .foregroundStyle(ThemeTokens.colors.ink)
                        Text("What's true right now?")
                            .font(AppTypography.display(size: 22, weight: .light))
                            .foregroundStyle(ThemeTokens.colors.inkDim)
                    }
                    .padding(.top, 24)

                    // Two side-by-side globe cards
                    HStack(spacing: 12) {
                        GlobeCard(
                            tone: .green,
                            count: greenCount,
                            title: "Green",
                            hint: "energy \u{00B7} wins \u{00B7} aliveness"
                        ) {
                            navigationPath.append(AppDestination.globeDetail(.green))
                        }

                        GlobeCard(
                            tone: .red,
                            count: redCount,
                            title: "Red",
                            hint: "friction \u{00B7} heaviness \u{00B7} stuck"
                        ) {
                            navigationPath.append(AppDestination.globeDetail(.red))
                        }
                    }
                    .padding(.top, 22)

                    // Unsorted pill (only if there are any)
                    if unsortedCount > 0 {
                        Button {
                            selectedTab = .entries
                            globeFilter = .unsorted
                        } label: {
                            HStack {
                                Text("\(unsortedCount) waiting to sort")
                                    .font(AppTypography.mono(size: 12, weight: .semibold))
                                    .foregroundStyle(ThemeTokens.colors.ink)
                                Text("\u{00B7} skip is fine")
                                    .font(AppTypography.monoXS)
                                    .foregroundStyle(ThemeTokens.colors.inkDim)
                                Spacer()
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(ThemeTokens.colors.inkDim)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(ThemeTokens.colors.line, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 12)
                    }

                    // Connection chip
                    HStack(spacing: 10) {
                        Circle()
                            .fill(viewModel.isOnline ? ThemeTokens.colors.green : ThemeTokens.colors.inkDim.opacity(0.6))
                            .frame(width: 8, height: 8)
                        Text(viewModel.isOnline
                            ? "synced just now"
                            : "offline \u{2014} saved locally, will sync")
                            .font(AppTypography.mono(size: 12, weight: .regular))
                            .foregroundStyle(ThemeTokens.colors.inkDim)
                    }
                    .padding(.top, 14)
                    .padding(.leading, 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18)
            }

            // Bottom action buttons
            VStack(spacing: 10) {
                recordButtonFull
                writeButtonFull

                if let recordingError {
                    Text(recordingError)
                        .font(AppTypography.monoXS)
                        .foregroundStyle(ThemeTokens.colors.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 110)
        }
    }

    private var greetingTitle: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning."
        case 12..<17: return "Good afternoon."
        case 17..<22: return "Good evening."
        default: return "Hello."
        }
    }

    // MARK: - Full-width action buttons

    private var recordButtonFull: some View {
        Button {
            handleRecordTap()
        } label: {
            HStack(spacing: 10) {
                recordButtonLabel
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .foregroundStyle(ThemeTokens.colors.bgElevated)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isRecordingProcessing
                          ? ThemeTokens.colors.inkDim
                          : ThemeTokens.colors.ink)
            )
        }
        .buttonStyle(.plain)
        .disabled(isRecordingProcessing)
    }

    private var isRecordingProcessing: Bool {
        recordingManager.state == .processing
    }

    @ViewBuilder
    private var recordButtonLabel: some View {
        if case .recording(let seconds) = recordingManager.state {
            Image(systemName: "stop.fill")
                .font(.system(size: 17, weight: .medium))
            Text(formatTime(seconds))
                .font(AppTypography.mono(size: 14, weight: .semibold))
                .tracking(0.8)
        } else if isRecordingProcessing {
            ProgressView().tint(ThemeTokens.colors.bgElevated)
            Text("PROCESSING")
                .font(AppTypography.mono(size: 14, weight: .semibold))
                .tracking(0.8)
        } else {
            Image(systemName: "mic.fill")
                .font(.system(size: 17, weight: .medium))
            Text("RECORD A FRAGMENT")
                .font(AppTypography.mono(size: 14, weight: .semibold))
                .tracking(0.8)
        }
    }

    private var writeButtonFull: some View {
        Button { selectedTab = .capture } label: {
            HStack(spacing: 10) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 17, weight: .medium))
                Text("WRITE IT DOWN")
                    .font(AppTypography.mono(size: 14, weight: .semibold))
                    .tracking(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 56)
            .foregroundStyle(ThemeTokens.colors.ink)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(ThemeTokens.colors.line, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Capture (Write) page

    private var capturePage: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // Editorial prompt
                    VStack(alignment: .leading, spacing: 2) {
                        Text("What\u{2019}s true")
                            .font(AppTypography.display(size: 24, weight: .light))
                            .foregroundStyle(ThemeTokens.colors.ink)
                        Text("right now?")
                            .font(Font.custom("Fraunces", size: 24).weight(.light).italic())
                            .foregroundStyle(ThemeTokens.colors.inkDim)
                    }
                    .padding(.top, 22)
                    .padding(.horizontal, 22)

                    // Editor card
                    VStack(spacing: 0) {
                        TextEditor(text: $viewModel.draftEntry)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 220)
                            .font(AppTypography.body)
                            .foregroundStyle(ThemeTokens.colors.ink)
                            .overlay(alignment: .topLeading) {
                                if viewModel.draftEntry.isEmpty {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("A fragment. A feeling. A half-formed thought.")
                                            .font(AppTypography.body)
                                            .foregroundStyle(ThemeTokens.colors.inkFaint)
                                        Text("No one reads this but you.")
                                            .font(AppTypography.body)
                                            .foregroundStyle(ThemeTokens.colors.inkFaint)
                                    }
                                    .padding(.top, 8)
                                    .allowsHitTesting(false)
                                }
                            }

                        // Hairline + footer
                        Rectangle()
                            .fill(ThemeTokens.colors.line.opacity(0.4))
                            .frame(height: 1)

                        HStack {
                            Text("\(viewModel.draftEntry.count) characters")
                                .font(AppTypography.monoXS)
                                .foregroundStyle(ThemeTokens.colors.inkDim)

                            Spacer()

                            HStack(spacing: 5) {
                                Circle()
                                    .fill(viewModel.isOnline ? ThemeTokens.colors.green : ThemeTokens.colors.inkFaint)
                                    .frame(width: 6, height: 6)
                                Text(viewModel.isOnline ? "will sync" : "saved locally")
                                    .font(AppTypography.mono(size: 10, weight: .regular))
                                    .foregroundStyle(ThemeTokens.colors.inkDim)
                            }
                        }
                        .padding(.top, 10)
                    }
                    .padding(18)
                    .frame(minHeight: 260)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(ThemeTokens.colors.line, lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 18)
                    .padding(.top, 18)

                    // Voice alternative row
                    Button {
                        handleRecordTap()
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(ThemeTokens.colors.ink)
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(ThemeTokens.colors.ink.opacity(0.08))
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Prefer your voice?")
                                    .font(AppTypography.mono(size: 13, weight: .medium))
                                    .foregroundStyle(ThemeTokens.colors.ink)
                                Text("Record instead \u{00B7} we\u{2019}ll transcribe it")
                                    .font(AppTypography.monoXS)
                                    .foregroundStyle(ThemeTokens.colors.inkDim)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(ThemeTokens.colors.inkDim)
                        }
                        .padding(14)
                        .frame(minHeight: 56)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(ThemeTokens.colors.line, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 18)
                    .padding(.top, 14)

                    // Reassurance
                    VStack(alignment: .leading, spacing: 2) {
                        Text("No prescriptions. No scoring.")
                            .font(Font.custom("Fraunces", size: 14).italic())
                            .foregroundStyle(ThemeTokens.colors.inkDim)
                        Text("Skip is always fine.")
                            .font(Font.custom("Fraunces", size: 14).italic())
                            .foregroundStyle(ThemeTokens.colors.inkDim)
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 16)

                    // Spacer for bottom actions
                    Spacer(minLength: 180)
                }
            }

            // Sticky bottom actions
            VStack(spacing: 0) {
                // Fade gradient
                LinearGradient(
                    colors: [Color(.systemBackground).opacity(0), Color(.systemBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 28)

                VStack(spacing: 8) {
                    // Primary save button
                    Button {
                        let content = viewModel.draftEntry.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !content.isEmpty else { return }
                        navigationPath.append(AppDestination.sortText(fragment: content))
                    } label: {
                        HStack(spacing: 8) {
                            Text("SAVE FRAGMENT")
                                .font(AppTypography.mono(size: 14, weight: .semibold))
                                .tracking(0.8)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .foregroundStyle(ThemeTokens.colors.bgElevated)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(hasDraftEntry ? ThemeTokens.colors.ink : ThemeTokens.colors.ink.opacity(0.25))
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!hasDraftEntry)

                    // Secondary stash button
                    Button {
                        let content = viewModel.draftEntry.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !content.isEmpty else { return }
                        let entry = SDEntry(
                            content: content,
                            source: "text",
                            globe: .unsorted
                        )
                        modelContext.insert(entry)
                        viewModel.draftEntry = ""
                    } label: {
                        Text("Stash without sorting \u{00B7} skip is fine")
                            .font(AppTypography.mono(size: 12, weight: .regular))
                            .foregroundStyle(ThemeTokens.colors.inkDim)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.plain)
                    .disabled(!hasDraftEntry)
                    .opacity(hasDraftEntry ? 1 : 0.4)
                }
                .padding(.top, 6)
                .padding(.horizontal, 18)
                .padding(.bottom, 120)
                .background(Color(.systemBackground))
            }
        }
    }

    // MARK: - Entries page

    private var entriesPage: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(ThemeTokens.colors.inkDim)

                TextField("Search entries or tags", text: $searchText)
                    .font(AppTypography.monoSM)
                    .textFieldStyle(.plain)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(ThemeTokens.colors.inkDim)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            .padding(.horizontal, 18)
            .padding(.top, 12)

            // Globe filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterChip(label: "All", globe: nil)
                    filterChip(label: "Green", globe: .green, color: ThemeTokens.colors.green)
                    filterChip(label: "Red", globe: .red, color: ThemeTokens.colors.red)
                    filterChip(label: "Mixed", globe: .mixed, color: ThemeTokens.colors.inkDim)
                    filterChip(label: "Unsorted", globe: .unsorted, color: ThemeTokens.colors.inkDim)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
            }

            // Entry list
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    if filteredEntries.isEmpty {
                        emptyCard(
                            title: globeFilter != nil || !searchText.isEmpty
                                ? "No matching entries"
                                : "No entries yet",
                            body: globeFilter != nil || !searchText.isEmpty
                                ? "Try adjusting your filters."
                                : "Use the Write tab or the home actions to create the first fragment."
                        )
                        .padding(.top, 8)
                    } else {
                        ForEach(filteredEntries) { entry in
                            Button {
                                selectedEntry = entry
                            } label: {
                                EntryCard(entry: entry)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 120)
            }
        }
    }

    // MARK: - Insights page

    private var insightsPage: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Weekly noticing")
                                .font(AppTypography.display(size: 24, weight: .light))
                                .foregroundStyle(ThemeTokens.colors.ink.opacity(0.94))

                            if let nextDate = nextInsightDate {
                                Text("Next available \(nextDate.formatted(date: .abbreviated, time: .omitted))")
                                    .font(AppTypography.monoXS)
                                    .foregroundStyle(ThemeTokens.colors.inkDim)
                            } else if allEntries.count < 3 {
                                Text("Need at least 3 entries to begin")
                                    .font(AppTypography.monoXS)
                                    .foregroundStyle(ThemeTokens.colors.inkDim)
                            } else {
                                Text("Patterns, not prescriptions.")
                                    .font(AppTypography.monoXS)
                                    .foregroundStyle(ThemeTokens.colors.inkDim)
                            }
                        }

                        Spacer()

                        Button {
                            Task {
                                await viewModel.generateInsight(
                                    entries: allEntries,
                                    insights: insights,
                                    context: modelContext
                                )
                            }
                        } label: {
                            if viewModel.isGeneratingInsight {
                                ProgressView()
                                    .tint(ThemeTokens.colors.ink.opacity(0.82))
                            } else {
                                Text("Generate")
                                    .font(AppTypography.mono(size: 11, weight: .semibold))
                                    .tracking(0.8)
                            }
                        }
                        .foregroundStyle(canGenerateInsight ? ThemeTokens.colors.ink.opacity(0.82) : ThemeTokens.colors.inkDim.opacity(0.4))
                        .disabled(!canGenerateInsight || viewModel.isGeneratingInsight)
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(AppTypography.monoXS)
                            .foregroundStyle(ThemeTokens.colors.red)
                    }

                    if insights.isEmpty {
                        emptyCard(
                            title: "No insights yet",
                            body: allEntries.count < 3
                                ? "Capture at least 3 fragments, then generate your first insight."
                                : "Tap Generate to spot your first pattern."
                        )
                    } else {
                        ForEach(insights) { insight in
                            InsightCard(insight: insight)
                        }
                    }
                }
                .padding(18)
                .background(cardContainer)
            }
            .padding(.horizontal, 18)
            .padding(.top, 24)
            .padding(.bottom, 120)
        }
    }

    // MARK: - Recording logic

    private func handleRecordTap() {
        recordingError = nil

        switch recordingManager.state {
        case .idle, .permissionDenied, .failed:
            Task {
                let granted = await recordingManager.requestMicrophonePermission()
                if !granted {
                    recordingManager.state = .permissionDenied
                    recordingError = "Microphone access needed. Enable in Settings."
                    return
                }
                recordingManager.startRecording()
            }

        case .recording:
            guard let audioURL = recordingManager.stopRecording() else {
                recordingError = "Recording file not found."
                recordingManager.reset()
                return
            }
            recordingManager.state = .processing
            Task {
                do {
                    let response = try await viewModel.transcribeAudio(fileURL: audioURL)
                    recordingManager.reset()
                    navigationPath.append(AppDestination.sortVoice(response))
                } catch {
                    recordingManager.reset()
                    recordingError = "Couldn't process recording. Try again."
                }
            }

        case .processing, .done:
            break
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }

    // MARK: - Filter chip

    private func filterChip(label: String, globe: GlobeType?, color: Color = ThemeTokens.colors.ink) -> some View {
        let isSelected = globeFilter == globe
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                globeFilter = globe
            }
        } label: {
            Text(label)
                .font(AppTypography.mono(size: 11, weight: .semibold))
                .tracking(0.4)
                .foregroundStyle(isSelected ? ThemeTokens.colors.bgElevated : ThemeTokens.colors.ink.opacity(0.7))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(isSelected ? color : Color(.secondarySystemBackground))
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Glass nav bar

    private var glassNavBar: some View {
        HStack(spacing: 8) {
            ForEach(HomeTab.allCases) { tab in
                Button {
                    if selectedTab == tab && tab == .entries {
                        globeFilter = nil
                        searchText = ""
                    }
                    selectedTab = tab
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16, weight: .semibold))

                        if selectedTab == tab {
                            Text(tab.title)
                                .font(.system(size: 13, weight: .semibold))
                        }
                    }
                    .foregroundStyle(selectedTab == tab ? navSelectedText : ThemeTokens.colors.ink.opacity(0.72))
                    .padding(.horizontal, selectedTab == tab ? 16 : 14)
                    .padding(.vertical, 13)
                    .background(
                        Capsule()
                            .fill(selectedTab == tab ? navSelectedFill : .clear)
                    )
                }
                .buttonStyle(.plain)
            }
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

    // MARK: - Helpers

    private func emptyCard(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(ThemeTokens.colors.ink.opacity(0.9))

            Text(body)
                .font(AppTypography.monoSM)
                .foregroundStyle(ThemeTokens.colors.inkDim)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
    }

    private var headerSubtitle: String {
        switch selectedTab {
        case .home: return "Two globes, one weekly noticing."
        case .capture: return "Capture first. Sort and meaning later."
        case .entries: return "Your fragments, kept visible."
        case .insights: return "Patterns, not prescriptions."
        }
    }

    private var hasDraftEntry: Bool {
        !viewModel.draftEntry.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var navSelectedFill: Color {
        colorScheme == .dark ? ThemeTokens.colors.ink.opacity(0.12) : ThemeTokens.colors.ink.opacity(0.10)
    }

    private var navSelectedText: Color {
        ThemeTokens.colors.ink
    }

    private var cardContainer: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(.ultraThinMaterial.opacity(0.32))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(ThemeTokens.colors.ink.opacity(0.1), lineWidth: 0.8)
            )
            .shadow(color: ThemeTokens.colors.ink.opacity(0.08), radius: 20, y: 8)
    }
}

// MARK: - Globe Card

private struct GlobeCard: View {
    let tone: GlobeType
    let count: Int
    let title: String
    let hint: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                StaticGlobeView(tone: tone, count: count)
                    .frame(width: 108, height: 108)

                VStack(spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(count)")
                            .font(AppTypography.display(size: 26, weight: .regular))
                            .foregroundStyle(ThemeTokens.colors.ink)
                        Text(count == 1 ? "entry" : "entries")
                            .font(AppTypography.mono(size: 13, weight: .regular))
                            .foregroundStyle(ThemeTokens.colors.inkDim.opacity(0.75))
                    }

                    Text(title.uppercased())
                        .font(AppTypography.mono(size: 11, weight: .semibold))
                        .tracking(0.8)
                        .foregroundStyle(tone == .green
                                         ? ThemeTokens.colors.greenDeep
                                         : ThemeTokens.colors.redDeep)

                    Text(hint)
                        .font(AppTypography.mono(size: 10, weight: .regular))
                        .foregroundStyle(ThemeTokens.colors.inkDim)
                }
            }
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(.secondarySystemBackground).opacity(0.4))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .strokeBorder(ThemeTokens.colors.line, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Static Globe View

private struct StaticGlobeView: View {
    let tone: GlobeType
    let count: Int

    private var base: Color {
        tone == .green ? ThemeTokens.colors.green : ThemeTokens.colors.red
    }
    private var edge: Color {
        tone == .green ? ThemeTokens.colors.greenDeep : ThemeTokens.colors.redDeep
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(base.opacity(0.18))
                .blur(radius: 14)
                .scaleEffect(1.2)

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
                        endRadius: 70
                    )
                )
                .overlay(Circle().stroke(base.opacity(0.22), lineWidth: 1))
                .overlay {
                    ForEach(0..<min(max(count, 4), 16), id: \.self) { i in
                        let angle = Double(i) * 2.39996323
                        let r = 14 + Double((i * 9) % 38)
                        Circle()
                            .fill(Color.white.opacity(0.75))
                            .frame(width: 3, height: 3)
                            .offset(x: cos(angle) * r, y: sin(angle) * r)
                    }
                }
        }
    }
}

// MARK: - Button styles

private struct OptionGlassButtonStyle: ButtonStyle {
    let strokeColor: Color
    let shadowColor: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.4)
                    .overlay(
                        Rectangle()
                            .stroke(strokeColor, lineWidth: 0.5)
                    )
            )
            .clipShape(Capsule())
            .shadow(color: shadowColor, radius: 10, x: 0, y: 6)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

struct FilledCapsuleButtonStyle: ButtonStyle {
    let fillColor: Color
    let textColor: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(textColor)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(fillColor)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.85), value: configuration.isPressed)
    }
}

// MARK: - Entry card

private struct EntryCard: View {
    let entry: SDEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(entry.globeType.title.uppercased())
                    .font(AppTypography.caption)
                    .tracking(1.2)
                    .foregroundStyle(tintColor.opacity(0.88))

                Spacer()

                Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(AppTypography.caption)
                    .foregroundStyle(.tertiary)
            }

            Text(entry.content)
                .font(AppTypography.body)
                .foregroundStyle(.primary.opacity(0.92))
                .lineLimit(4)
                .multilineTextAlignment(.leading)

            if !entry.pointers.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(entry.pointers, id: \.self) { pointer in
                            Text("#\(pointer)")
                                .font(AppTypography.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill(.primary.opacity(0.08))
                                )
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var tintColor: Color {
        switch entry.globeType {
        case .green: return ThemeTokens.colors.green
        case .red: return ThemeTokens.colors.red
        case .mixed, .unsorted: return ThemeTokens.colors.inkDim
        }
    }
}

// MARK: - Insight card

private struct InsightCard: View {
    let insight: SDInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(insight.type.title.uppercased())
                .font(AppTypography.caption)
                .tracking(1.2)
                .foregroundStyle(insightTint.opacity(0.7))

            Text(insight.title)
                .font(AppTypography.display(size: 22, weight: .light))
                .foregroundStyle(.primary.opacity(0.94))

            Text(insight.body)
                .font(AppTypography.monoSM)
                .foregroundStyle(.secondary)

            Text(insight.evidenceSummary)
                .font(AppTypography.monoXS)
                .foregroundStyle(.tertiary)

            Text(insight.createdAt.formatted(date: .abbreviated, time: .omitted))
                .font(AppTypography.caption)
                .foregroundStyle(.quaternary)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var insightTint: Color {
        switch insight.type {
        case .asymmetry: return ThemeTokens.colors.green
        case .contradiction: return ThemeTokens.colors.red
        case .drift: return .orange
        case .silence: return ThemeTokens.colors.inkDim
        case .realityCheck: return .purple
        case .question: return ThemeTokens.colors.ink
        }
    }
}

// MARK: - Pointer Cloud View

struct PointerCloudView: View {
    @Query(sort: \SDEntry.createdAt, order: .reverse) private var entries: [SDEntry]
    @Environment(\.modelContext) private var modelContext

    private var pointerCounts: [(tag: String, count: Int)] {
        var counts: [String: Int] = [:]
        for entry in entries {
            for pointer in entry.pointers {
                counts[pointer, default: 0] += 1
            }
        }
        return counts.map { (tag: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                Text("All tags across your entries. Tap to remove a tag from every entry that uses it.")
                    .font(AppTypography.monoXS)
                    .foregroundStyle(ThemeTokens.colors.inkDim)

                if pointerCounts.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("No tags yet")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(ThemeTokens.colors.ink.opacity(0.9))

                        Text("Tags are added during the Sort step after capturing a fragment.")
                            .font(AppTypography.monoSM)
                            .foregroundStyle(ThemeTokens.colors.inkDim)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground))
                } else {
                    WrappingHStack(spacing: 10) {
                        ForEach(pointerCounts, id: \.tag) { item in
                            pointerBubble(tag: item.tag, count: item.count)
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 24)
            .padding(.bottom, 48)
        }
        .navigationTitle("Tags")
        .navigationBarTitleDisplayMode(.large)
    }

    @State private var tagToDelete: String?
    @State private var showDeleteAlert = false

    private func pointerBubble(tag: String, count: Int) -> some View {
        Button {
            tagToDelete = tag
            showDeleteAlert = true
        } label: {
            HStack(spacing: 6) {
                Text("#\(tag)")
                    .font(AppTypography.mono(size: 12, weight: .medium))
                Text("\(count)")
                    .font(AppTypography.mono(size: 10, weight: .regular))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
        .alert("Remove tag?", isPresented: $showDeleteAlert) {
            Button("Remove from all entries", role: .destructive) {
                if let tag = tagToDelete {
                    removeTag(tag)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let tag = tagToDelete {
                Text("This will remove #\(tag) from \(entries.filter { $0.pointers.contains(tag) }.count) entries.")
            }
        }
    }

    private func removeTag(_ tag: String) {
        for entry in entries where entry.pointers.contains(tag) {
            entry.pointers.removeAll { $0 == tag }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [SDEntry.self, SDInsight.self], inMemory: true)
}
