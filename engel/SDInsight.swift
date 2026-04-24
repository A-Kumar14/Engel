//
//  SDInsight.swift
//  engel
//

import Foundation
import SwiftData

@Model
final class SDInsight {
    var insightType: String
    var title: String
    var body: String
    var evidenceSummary: String
    var createdAt: Date

    init(
        insightType: InsightType,
        title: String,
        body: String,
        evidenceSummary: String
    ) {
        self.insightType = insightType.rawValue
        self.title = title
        self.body = body
        self.evidenceSummary = evidenceSummary
        self.createdAt = Date()
    }

    var type: InsightType {
        InsightType(rawValue: insightType) ?? .question
    }
}
