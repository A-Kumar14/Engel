//
//  SDEntry.swift
//  engel
//

import Foundation
import SwiftData

@Model
final class SDEntry {
    var content: String
    var source: String
    var globe: String
    var aiConfidence: Double?
    var createdAt: Date
    var pointers: [String]

    init(
        content: String,
        source: String,
        globe: GlobeType,
        aiConfidence: Double? = nil,
        pointers: [String] = []
    ) {
        self.content = content
        self.source = source
        self.globe = globe.rawValue
        self.aiConfidence = aiConfidence
        self.createdAt = Date()
        self.pointers = pointers
    }

    var globeType: GlobeType {
        get { GlobeType(rawValue: globe) ?? .unsorted }
        set { globe = newValue.rawValue }
    }
}
