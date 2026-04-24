//
//  HomeViewModel.swift
//  engel
//

import Foundation
import Observation
import SwiftData

@Observable
@MainActor
final class HomeViewModel {
    // UI state
    var draftEntry = ""
    var isCreatingEntry = false
    var isGeneratingInsight = false
    var isOnline = false
    var errorMessage: String?

    private let client: BackendClient

    init(client: BackendClient? = nil) {
        self.client = client ?? BackendClient()
    }

    // MARK: - Transcription (requires backend)

    func transcribeAudio(fileURL: URL) async throws -> TranscriptResponse {
        try await client.transcribeAudio(fileURL: fileURL)
    }

    // MARK: - Insight generation

    func generateInsight(entries: [SDEntry], insights: [SDInsight], context: ModelContext) async {
        isGeneratingInsight = true
        errorMessage = nil
        defer { isGeneratingInsight = false }

        // Throttle: one per week
        if let latest = insights.first {
            let nextAllowed = latest.createdAt.addingTimeInterval(7 * 86400)
            if nextAllowed > Date() {
                errorMessage = "Next insight available \(nextAllowed.formatted(date: .abbreviated, time: .omitted))."
                return
            }
        }

        guard entries.count >= 3 else {
            errorMessage = "Need at least 3 entries to spot patterns."
            return
        }

        // Try backend first
        do {
            let insight = try await client.generateWeeklyInsight()
            let sd = SDInsight(
                insightType: insight.insightType,
                title: insight.title,
                body: insight.body,
                evidenceSummary: insight.evidenceSummary
            )
            context.insert(sd)
            return
        } catch {
            // Backend unavailable — fall back to local patterns
        }

        generateLocalInsight(from: entries, context: context)
    }

    // MARK: - Local pattern detection

    private func generateLocalInsight(from entries: [SDEntry], context: ModelContext) {
        let green = entries.filter { $0.globe == "green" }
        let red = entries.filter { $0.globe == "red" }

        // Asymmetry
        let greenCount = green.count
        let redCount = red.count
        if greenCount >= 2 * max(redCount, 1) || redCount >= 2 * max(greenCount, 1) {
            let dominant = greenCount > redCount ? "green" : "red"
            let quieter = dominant == "green" ? "red" : "green"
            let insight = SDInsight(
                insightType: .asymmetry,
                title: "The \(dominant) globe is louder",
                body: "Your recent fragments lean heavily \(dominant). The \(quieter) globe has been quieter. Not a problem — just a pattern to notice.",
                evidenceSummary: "\(greenCount) green, \(redCount) red across \(entries.count) entries"
            )
            context.insert(insight)
            return
        }

        // Drift: compare recent vs older entries
        let sorted = entries.sorted { $0.createdAt > $1.createdAt }
        let recent = Array(sorted.prefix(5))
        let older = Array(sorted.dropFirst(5).prefix(5))
        if !older.isEmpty {
            let recentGreen = Double(recent.filter { $0.globe == "green" }.count) / Double(recent.count)
            let olderGreen = Double(older.filter { $0.globe == "green" }.count) / Double(older.count)
            if abs(recentGreen - olderGreen) > 0.4 {
                let direction = recentGreen > olderGreen ? "greener" : "redder"
                let insight = SDInsight(
                    insightType: .drift,
                    title: "Things have shifted \(direction) lately",
                    body: "Your recent entries feel different from earlier ones. Something may have changed — or you're noticing different things.",
                    evidenceSummary: "Recent: \(Int(recentGreen * 100))% green vs earlier: \(Int(olderGreen * 100))% green"
                )
                context.insert(insight)
                return
            }
        }

        // Silence: check if any entries in last 3 days
        let threeDaysAgo = Date().addingTimeInterval(-3 * 86400)
        let recentEntries = entries.filter { $0.createdAt > threeDaysAgo }
        if recentEntries.isEmpty && entries.count >= 5 {
            let insight = SDInsight(
                insightType: .silence,
                title: "It's been quiet",
                body: "No new fragments in the last few days. Sometimes silence is its own signal — or you've just been busy.",
                evidenceSummary: "Last entry: \(sorted.first?.createdAt.formatted(date: .abbreviated, time: .omitted) ?? "unknown")"
            )
            context.insert(insight)
            return
        }

        // Contradiction: green and red entries with overlapping pointers
        let greenPointers = Set(green.flatMap { $0.pointers })
        let redPointers = Set(red.flatMap { $0.pointers })
        let overlap = greenPointers.intersection(redPointers)
        if !overlap.isEmpty {
            let tags = overlap.prefix(3).map { "#\($0)" }.joined(separator: ", ")
            let insight = SDInsight(
                insightType: .contradiction,
                title: "Same themes, different feelings",
                body: "The tags \(tags) appear in both globes. The same parts of life are fueling you and draining you.",
                evidenceSummary: "\(overlap.count) shared tags between green and red"
            )
            context.insert(insight)
            return
        }

        // Default observation
        let uniquePointers = Set(entries.flatMap { $0.pointers })
        let insight = SDInsight(
            insightType: .question,
            title: "A moment to notice",
            body: "You've captured \(entries.count) fragments across \(uniquePointers.count) themes. Patterns emerge over time — keep going.",
            evidenceSummary: "\(greenCount) green, \(redCount) red, \(uniquePointers.count) unique tags"
        )
        context.insert(insight)
    }
}
