//
//  APIModels.swift
//  engel
//

import Foundation

enum GlobeType: String, Codable, CaseIterable, Identifiable {
    case green
    case red
    case mixed
    case unsorted

    var id: String { rawValue }

    var title: String {
        switch self {
        case .green:
            return "Green"
        case .red:
            return "Red"
        case .mixed:
            return "Mixed"
        case .unsorted:
            return "Unsorted"
        }
    }
}

enum InsightType: String, Codable, Identifiable {
    case asymmetry
    case contradiction
    case drift
    case silence
    case realityCheck = "reality_check"
    case question

    var id: String { rawValue }

    var title: String {
        rawValue.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

struct Pointer: Codable, Identifiable, Hashable {
    let id: Int
    let label: String
    let source: String
}

struct Entry: Codable, Identifiable, Hashable {
    let id: Int
    let content: String
    let source: String
    let globe: GlobeType
    let aiConfidence: String?
    let createdAt: Date
    let pointers: [Pointer]

    enum CodingKeys: String, CodingKey {
        case id
        case content
        case source
        case globe
        case aiConfidence = "ai_confidence"
        case createdAt = "created_at"
        case pointers
    }
}

struct Insight: Codable, Identifiable, Hashable {
    let id: Int
    let insightType: InsightType
    let title: String
    let body: String
    let evidenceSummary: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case insightType = "insight_type"
        case title
        case body
        case evidenceSummary = "evidence_summary"
        case createdAt = "created_at"
    }
}

struct HealthResponse: Codable {
    let status: String
    let app: String
}

struct PointerCreateRequest: Encodable {
    let label: String
    let source: String
}

struct EntryCreateRequest: Encodable {
    let content: String
    let source: String
    let globe: GlobeType
    let aiConfidence: String?
    let pointers: [PointerCreateRequest]

    enum CodingKeys: String, CodingKey {
        case content
        case source
        case globe
        case aiConfidence = "ai_confidence"
        case pointers
    }
}

struct TranscriptResponse: Codable, Hashable {
    let transcript: String
    let suggestedGlobe: GlobeType
    let suggestedPointers: [String]
    let confidence: Double

    enum CodingKeys: String, CodingKey {
        case transcript
        case suggestedGlobe = "suggested_globe"
        case suggestedPointers = "suggested_pointers"
        case confidence
    }
}
